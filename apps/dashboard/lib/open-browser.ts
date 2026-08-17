// Server-only: open the operator's browser at `url`. The dashboard runs on the
// operator's own machine, so MCP OAuth can drive it directly - there the
// dashboard builds the authorize URL itself and no CLI is involved. The harness
// logins (grok/codex/kimi) deliberately do NOT call this: their CLIs open the
// browser themselves, and opening it again duplicates the tab.
import { execFile } from 'child_process'
import { mkdirSync, writeFileSync } from 'fs'
import { join } from 'path'

// Fire-and-forget; a failure to auto-open isn't fatal — every caller also
// surfaces the URL to the operator.
export function openBrowser(url: string): void {
  // Best-effort fallback for environments where the popup fails: persist the
  // last URL to outputs/.pending-authorize-url.md (gitignored via the existing
  // outputs/.pending-*.md rule) so the operator can open it manually.
  try {
    mkdirSync(join(process.cwd(), 'outputs'), { recursive: true })
    writeFileSync(join(process.cwd(), 'outputs', '.pending-authorize-url.md'), url)
  } catch { /* best-effort */ }
  // win32 uses PowerShell Start-Process with a single-quoted URL: the previous
  // `cmd /c start` path split the command at each `&`, truncating OAuth
  // authorize URLs to their first query parameter (HTTP 400 at the AS).
  const cmd = process.platform === 'darwin' ? 'open'
    : process.platform === 'win32' ? 'powershell'
    : 'xdg-open'
  const args = process.platform === 'win32'
    ? ['-NoProfile', '-NonInteractive', '-Command', `Start-Process -FilePath '${url.replace(/'/g, '')}'`]
    : [url]
  execFile(cmd, args, () => {})
}
