/**
 * Desktop notifications when Pi needs the user, via Ghostty's own OSC 777
 * escape sequence rather than a subprocess.
 *
 * We standardize on Ghostty (or a Ghostty-derived build — this machine's
 * is rebranded as "Macterm" but still reports `TERM_PROGRAM=ghostty` /
 * `TERM=xterm-ghostty`) across both Macs, so it's simpler and more direct
 * to plug into its native notification support than to shell out to
 * `osascript`. Ghostty parses OSC 777 (`ESC ] 777 ; notify ; title ; body`)
 * itself and forwards it to macOS's UNUserNotificationCenter as a real
 * Notification Center alert — no child process. Gated behind Ghostty's own
 * `desktop-notifications` config (on by default; see ghostty docs).
 *
 * Macterm's own fork of that path (thdxg/macterm#19, #298, #300) adds
 * several behaviors we inherit for free just by using OSC 777 — plus a
 * couple of quirks worth knowing about:
 *   - It tags every notification with the originating pane/project (#19),
 *     so clicking the banner — or its explicit "Show" action (added in
 *     #300) — focuses that exact pane; no work needed here. Swiping a
 *     banner away is now a plain dismissal (#300): only a tap or "Show"
 *     navigates.
 *   - It stamps the pane's own display title into the banner's subtitle
 *     (#300) — the same string that pane's sidebar row shows — so a banner
 *     from any of several open panes says which one, again without this
 *     extension supplying anything itself.
 *   - It suppresses the banner when Macterm is the active app *and* that
 *     exact pane is focused (you're already looking at it). A quiet test
 *     run in the foreground pane you're watching is this, not a bug.
 *   - It clears a pane's already-delivered banners from Notification Center
 *     once that pane regains focus or its surface is destroyed (#300), so
 *     they no longer pile up indefinitely for panes you've since revisited
 *     or closed.
 *   - It plays the default system alert sound for every notification
 *     (#298), matching Ghostty's and standard macOS app behavior — this
 *     extension used to shell out to play its own sound via a
 *     `PI_NOTIFY_SOUND_CMD` env var (same opt-in hook as pi-notify,
 *     https://pi.dev/packages/pi-notify) before Macterm did this itself;
 *     that hook is gone now (see git history). Sound is opt-out only at the
 *     OS level (System Settings → Notifications → Macterm → Sounds), not
 *     from this extension. If Macterm requested permission before #298
 *     shipped (Aug 2026), it may have been granted alert-only — macOS
 *     doesn't retroactively add the sound permission, so check that toggle
 *     if banners stay silent.
 *   - Macterm also fires its own separate "Command Finished" notification
 *     per command (its skin on Ghostty's `notify-on-command-finish`
 *     feature) — unrelated to this extension; disable with
 *     `notify-on-command-finish = never` in ghostty config if unwanted.
 *
 * Two cases count as "user interaction required":
 *   - `agent_settled`: the turn is fully done and Pi is waiting for the
 *     next prompt. Using `agent_settled` rather than `agent_end` matters:
 *     `agent_end` also fires before an auto-retry, auto-compact-and-retry,
 *     or a queued follow-up message, none of which actually need the user.
 *   - `ui_prompt_start`: Pi is blocked mid-turn on a confirm/select/input
 *     dialog (e.g. a tool-approval prompt). Nested/overlapping prompts
 *     coalesce into one outer span, so this fires once per wait, not once
 *     per dialog.
 *
 * Both handlers check `ctx.hasUI` first, so a `-p`/`--mode json` one-shot
 * run (nothing interactive to return to) stays silent.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function isGhosttyDerived(): boolean {
  return (
    process.env.TERM_PROGRAM === "ghostty" ||
    process.env.TERM === "xterm-ghostty" ||
    Boolean(process.env.GHOSTTY_RESOURCES_DIR)
  );
}

function notify(title: string, message: string): void {
  if (!isGhosttyDerived()) return;

  // OSC 777: ESC ] 777 ; notify ; <title> ; <body> ESC \
  process.stdout.write(`\x1b]777;notify;${title};${message}\x1b\\`);
}

export default function (pi: ExtensionAPI) {
  pi.on("agent_settled", async (_event, ctx) => {
    if (!ctx.hasUI) return;
    notify("Pi", "Ready for input");
  });

  pi.on("ui_prompt_start", async (event, ctx) => {
    if (!ctx.hasUI) return;
    notify("Pi", event.title ?? `Waiting for ${event.kind}`);
  });
}
