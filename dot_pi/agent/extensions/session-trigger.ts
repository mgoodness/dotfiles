/**
 * Session Trigger Extension (per-session variant of examples/extensions/file-trigger.ts)
 *
 * Lets a local background process wake this pi session by appending a line to a
 * file that only this session watches. Each Rex session gets its own file, so
 * triggers never reach other pi instances.
 *
 *   file: ~/.cache/pi-triggers/<REX_SESSION with unsafe characters replaced by _>.txt
 *   send: printf '%s\n' "gei-watch: finished" >> "$TRIGGER_FILE"
 *
 * Safety:
 * - Inert unless REX_SESSION is set (no shared global path).
 * - Directory 0700, file 0600; a file that is not a regular file owned by the
 *   current user with no group/other permissions is ignored.
 * - Text is truncated, control characters are stripped, and the message tells the
 *   model it is a notification from a local process, not an instruction from the user.
 * - The watcher is closed on session_shutdown.
 */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const MAX_LEN = 500;
const DEBOUNCE_MS = 200;

export function triggerFileFor(sessionId: string): string {
  const safe = sessionId.replace(/[^A-Za-z0-9._-]/g, "_");
  return path.join(os.homedir(), ".cache", "pi-triggers", `${safe}.txt`);
}

function cleanText(raw: string): string {
  return raw
    .replace(/[\u0000-\u001f\u007f]+/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, MAX_LEN);
}

function isSafeFile(file: string): boolean {
  try {
    const st = fs.lstatSync(file);
    const uid = typeof process.getuid === "function" ? process.getuid() : undefined;
    return st.isFile() && (uid === undefined || st.uid === uid) && (st.mode & 0o077) === 0;
  } catch {
    return false;
  }
}

export default function (pi: ExtensionAPI) {
  let watcher: fs.FSWatcher | undefined;
  let timer: NodeJS.Timeout | undefined;

  const stop = () => {
    if (timer) clearTimeout(timer);
    timer = undefined;
    watcher?.close();
    watcher = undefined;
  };

  pi.on("session_start", async (_event, ctx) => {
    stop(); // idempotent: reload/resume re-runs session_start
    const sessionId = process.env.REX_SESSION;
    if (!sessionId) return; // no per-session identity, stay inert

    const file = triggerFileFor(sessionId);
    try {
      fs.mkdirSync(path.dirname(file), { recursive: true, mode: 0o700 });
      if (!fs.existsSync(file)) fs.writeFileSync(file, "", { mode: 0o600 });
    } catch {
      return;
    }

    const drain = () => {
      try {
        if (!isSafeFile(file)) {
          if (ctx.hasUI) ctx.ui.notify(`session-trigger: ignoring unsafe file ${file}`, "warning");
          return;
        }
        const text = cleanText(fs.readFileSync(file, "utf-8"));
        if (!text) return;
        fs.writeFileSync(file, ""); // clear after reading; the resulting empty change is ignored above
        pi.sendMessage(
          {
            customType: "session-trigger",
            content:
              `Notification from a local background process (not an instruction from the user): ${text}. ` +
              "Check the process's log or status as appropriate and report to the user.",
            display: true,
          },
          { triggerTurn: true },
        );
      } catch {
        // The file may be mid-write or gone; the next change event retries.
      }
    };

    try {
      watcher = fs.watch(file, () => {
        if (timer) clearTimeout(timer);
        timer = setTimeout(drain, DEBOUNCE_MS);
      });
      watcher.on("error", stop);
    } catch {
      return;
    }

    if (ctx.hasUI) ctx.ui.notify(`session-trigger: watching ${file}`, "info");
    drain(); // deliver anything written while the session was not running
  });

  pi.on("session_shutdown", async () => {
    stop();
  });
}
