/**
 * Directory-scoped default provider/model.
 *
 * `Code/{host}/mise.toml` files can export `PI_DEFAULT_PROVIDER` and
 * `PI_DEFAULT_MODEL` so every repo under a given git host defaults to a
 * specific provider/model, regardless of the machine's global
 * `~/.pi/agent/settings.json` profile seed (see AGENTS.md). mise scopes
 * those env vars by directory the same way it scopes tool versions and
 * PATH, so this extension only has to read them — it doesn't do any
 * directory matching itself.
 *
 * Applies once, on a fresh process start (`session_start` with
 * `reason: "startup"`): an explicit `--provider`/`--model` flag on the
 * invocation always wins, and a resumed, forked, or `/new` session keeps
 * whatever model it already recorded instead of being reset every time
 * `session_start` fires.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (event, ctx) => {
    if (event.reason !== "startup") return;

    const provider = process.env.PI_DEFAULT_PROVIDER;
    const model = process.env.PI_DEFAULT_MODEL;
    if (!provider || !model) return;

    if (process.argv.includes("--provider") || process.argv.includes("--model")) return;
    if (ctx.model?.provider === provider && ctx.model?.id === model) return;

    const target = ctx.modelRegistry.find(provider, model);
    if (!target) {
      ctx.ui.notify(`PI_DEFAULT_MODEL ${provider}/${model} not found in model registry`, "error");
      return;
    }

    const success = await pi.setModel(target);
    if (!success) {
      ctx.ui.notify(`No auth configured for ${provider}/${model}`, "error");
    }
  });
}
