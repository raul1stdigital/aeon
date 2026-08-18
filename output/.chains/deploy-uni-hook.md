✅ deploy-uni-hook: live on Base

**Uniswap v4 hook deployed live on Base mainnet**

Dynamic-fee demo pool encoding fresh CoinMarketCap ETH 24h-change data.

- Hook: [0xF8746df7...50C0](https://basescan.org/address/0xF8746df7b130f60386b3941FCE25801B7e3650C0)
- Data: ETH +0.104876% 24h → +10 bps, baked into fee logic (0.01 USDC paid via x402)
- Fee verified on-chain: first swap emitted feeApplied=4000 = BASE_FEE(3000) + ETH_24H_PREMIUM(1000)
- Skipped a redundant 0.0004 ETH gas transfer — deployer already held ~13x the ~0.000059 ETH this deploy needed
- Est. cost: 0.000059 ETH

🔗 https://basescan.org/address/0xF8746df7b130f60386b3941FCE25801B7e3650C0