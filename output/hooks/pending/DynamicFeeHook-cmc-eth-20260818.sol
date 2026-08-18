// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// TEMPLATE: dynamic-fee hook.
// Flags required in the address: AFTER_INITIALIZE, BEFORE_SWAP, AFTER_SWAP (0x10C0).
// The pool MUST be initialized with fee = LPFeeLibrary.DYNAMIC_FEE_FLAG.
//
// Default logic = volatility fee: the fee for a swap grows with the price move
// of the previous swap. Edit `_computeFee` to change the policy (time decay,
// directional fee, volume tiers, etc.). Keep the AEON:LOGIC markers so the
// deploy-uni-hook skill can find the region it may rewrite.

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";

contract DynamicFeeHook {
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;

    IPoolManager public immutable poolManager;

    // fee parameters (hundredths of a bip; 3000 = 0.30%)
    uint24 public constant BASE_FEE = 3000;
    uint24 public constant MIN_FEE = 500;
    uint24 public constant MAX_FEE = 50000;
    uint24 public constant FEE_PER_TICK = 100;

    mapping(PoolId => int24) public tickAtSwapStart;
    mapping(PoolId => uint256) public lastMove;

    event DynamicFee(PoolId indexed id, uint256 lastMove, uint24 feeApplied);

    error NotPoolManager();

    constructor(IPoolManager _pm) {
        poolManager = _pm;
    }

    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert NotPoolManager();
        _;
    }

    function afterInitialize(address, PoolKey calldata key, uint160, int24 tick)
        external
        onlyPoolManager
        returns (bytes4)
    {
        tickAtSwapStart[key.toId()] = tick;
        return IHooks.afterInitialize.selector;
    }

    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, bytes calldata)
        external
        onlyPoolManager
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        PoolId id = key.toId();
        (, int24 curTick,,) = poolManager.getSlot0(id);
        tickAtSwapStart[id] = curTick;

        uint24 fee = _computeFee(id);
        emit DynamicFee(id, lastMove[id], fee);
        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, fee | LPFeeLibrary.OVERRIDE_FEE_FLAG);
    }

    function afterSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        external
        onlyPoolManager
        returns (bytes4, int128)
    {
        PoolId id = key.toId();
        (, int24 newTick,,) = poolManager.getSlot0(id);
        int256 diff = int256(newTick) - int256(tickAtSwapStart[id]);
        lastMove[id] = diff >= 0 ? uint256(diff) : uint256(-diff);
        return (IHooks.afterSwap.selector, int128(0));
    }

    // --- AEON:LOGIC START (the deploy-uni-hook skill may rewrite this body) ---
    //
    // MARKET-ANCHORED VOLATILITY FEE.
    //
    // The 24h ETH change below is not a guess — it was *purchased* earlier in this
    // same chain run: an x402 micropayment of $0.01 USDC on Base to CoinMarketCap
    // /v2/cryptocurrency/quotes/latest for ETH (id=1027), 2026-08-18.
    // Snapshot: price $1,893.76, 24h change -0.20%  ->  -20 bps (rounded).
    //
    // Both figures are burned into the bytecode as public constants, so the
    // deployed hook visibly carries the data the agent paid for and anyone can
    // read it back on-chain:
    //     cast call <hook> "ETH_24H_CHANGE_BPS()(int256)"    -> -20
    //     cast call <hook> "CMC_ETH_PRICE_USD_E8()(uint256)" -> 189376000000
    //
    // Policy:
    //     fee = BASE_FEE
    //         + |24h change| * VOL_FEE_PER_BPS   <- market-wide, fixed at deploy
    //         + lastMove     * FEE_PER_TICK      <- this pool's own last swap, live
    // and the market-wide term is scaled by DOWNSIDE_MULT_BPS when the 24h change
    // was negative: LPs face worse adverse selection into a falling tape, so they
    // get paid more for it.
    //
    // With this snapshot: |-20| * 25 = 500, * 1.5 = 750, so an idle pool quotes
    // 3000 + 750 = 3750 = 0.375% (vs the 0.30% template default). The market term
    // is a deploy-time constant by design — the hook is a snapshot of the moment
    // it was bought, not a live oracle read.

    int256 public constant ETH_24H_CHANGE_BPS = -20; // CMC 24h change, rounded to bps
    uint256 public constant CMC_ETH_PRICE_USD_E8 = 189_376_000_000; // $1,893.76 * 1e8
    uint256 public constant CMC_SNAPSHOT_DATE = 20_260_818; // YYYYMMDD, UTC
    uint24 public constant VOL_FEE_PER_BPS = 25; // fee units per bp of 24h move
    uint256 public constant DOWNSIDE_MULT_BPS = 15_000; // 1.5x on a negative tape

    function _computeFee(PoolId id) internal view returns (uint24) {
        int256 change = ETH_24H_CHANGE_BPS;
        uint256 move = change >= 0 ? uint256(change) : uint256(-change);

        uint256 marketTerm = move * uint256(VOL_FEE_PER_BPS);
        if (change < 0) {
            marketTerm = (marketTerm * DOWNSIDE_MULT_BPS) / 10_000;
        }

        uint256 fee = uint256(BASE_FEE) + marketTerm + lastMove[id] * uint256(FEE_PER_TICK);
        if (fee < MIN_FEE) return MIN_FEE;
        if (fee > MAX_FEE) return MAX_FEE;
        return uint24(fee);
    }
    // --- AEON:LOGIC END ---
}
