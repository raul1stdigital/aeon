⚠️ deploy-uni-hook: no toolchain

## deploy-uni-hook — blocked: no toolchain

**`DEPLOY_HOOK_NO_TOOLCHAIN`** — nothing was compiled, simulated, or deployed.

Brief: `template:dynamic chain:base-sepolia` — a dynamic-fee pool encoding the CoinMarketCap ETH 24h change the agent just paid for.

**Root cause:** the `Stage deploy-uni-hook toolchain` step (aeon.yml step 18) reported success, but Foundry never landed — `~/.foundry` and `~/hookbuild` do not exist and `./hook-deploy.sh` was not copied to the repo root. `scripts/stage-deploy-uni-hook.sh` hit its `WARN forge unavailable after install attempt` early-exit, so the `curl -L https://foundry.paradigm.xyz | bash` install failed on the runner. The script is best-effort (`exit 0`), so the workflow step went green anyway.

**What was produced:** the hook source, with the purchased data burned in as public constants — `ETH_24H_CHANGE_BPS = -20` (from $1,893.76 / -0.20%), `CMC_ETH_PRICE_USD_E8 = 189376000000`. Idle-pool fee moves 0.30% → 0.375%.

`output/hooks/pending/DynamicFeeHook-cmc-eth-20260818.sol`

Note this was a **dry-run** regardless (no `arm:`), so no broadcast was ever going to happen — but the compile/mine/simulate gates were skipped too, so the source is **unverified**. Re-run once staging is fixed.