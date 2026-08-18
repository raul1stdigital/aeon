🚨 Heartbeat: fleet degraded

## Heartbeat — 2026-08-18

**Overall: 🔴 DEGRADED**

🔴 FAILED: **heartbeat** — 0/2 runs succeeded, last failure 2026-08-18 01:43 UTC, `consecutive_failures=2`. This is the only enabled scheduled skill in `aeon.yml` and it has never completed successfully yet (this is its 3rd attempt).
🔴 FAILED: **finance-district-mcp** (on-demand) — 0/2 runs succeeded, last failure 2026-08-17 14:53 UTC, `consecutive_failures=2`.
🔴 FAILED: **chain:fd-hook-demo** (on-demand chain) — failed 2026-08-17 15:10 UTC.

All three share the same error signature (`claude exited 1`, truncated JSON around `service_tier`/`modelUsage`) — worth checking whether this is a shared harness/runtime issue rather than three unrelated skill bugs.

No stalled PRs (none open). Issues are disabled on this repo, so urgent-issue check was skipped. No flagged memory items beyond the unconfigured fork defaults (notification channels, first digest).

`docs/status.md` regenerated: 🔴 DEGRADED.