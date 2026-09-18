/**
 * OpenRouter credits in the status line.
 *
 * Shows the remaining OpenRouter credit balance in pi's footer (prefixed with
 * 💰 so a bare dollar figure doesn't read as unexplained) whenever the active
 * model's provider is OpenRouter, and hides itself for every other provider.
 *
 * The balance comes from OpenRouter's `/api/v1/credits` endpoint, which reports
 * lifetime totals (`total_credits`, `total_usage`); remaining is the difference.
 * The credential is resolved through pi's model registry, so this works whether
 * the key came from `OPENROUTER_API_KEY` or an `/login`-stored one.
 *
 * Fetching is throttled — on session start, on provider change, and at most
 * once per CACHE_TTL_MS at the end of a turn. `/credits` forces a refresh.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const PROVIDER = "openrouter";
const STATUS_KEY = "openrouter-credits";
const CREDITS_URL = "https://openrouter.ai/api/v1/credits";
const CACHE_TTL_MS = 60_000;
const REQUEST_TIMEOUT_MS = 5_000;
const LOW_BALANCE_USD = 5;
const CRITICAL_BALANCE_USD = 1;

interface Balance {
  remaining: number;
  /** Lifetime credits purchased. */
  total: number;
  /** Lifetime credits consumed. */
  usage: number;
}

let cached: { fetchedAt: number; balance: Balance } | undefined;

function usd(value: number): string {
  return `$${value.toFixed(2)}`;
}

async function fetchBalance(
  apiKey: string,
  signal: AbortSignal | undefined,
): Promise<Balance | undefined> {
  const timeout = new AbortController();
  const timer = setTimeout(() => timeout.abort(), REQUEST_TIMEOUT_MS);
  try {
    const response = await fetch(CREDITS_URL, {
      headers: { Authorization: `Bearer ${apiKey}` },
      signal: signal ? AbortSignal.any([signal, timeout.signal]) : timeout.signal,
    });
    if (!response.ok) return undefined;

    const body = (await response.json()) as {
      data?: { total_credits?: unknown; total_usage?: unknown };
    };
    const total = body.data?.total_credits;
    const usage = body.data?.total_usage;
    if (typeof total !== "number" || typeof usage !== "number") return undefined;

    return { total, usage, remaining: total - usage };
  } catch {
    return undefined;
  } finally {
    clearTimeout(timer);
  }
}

function render(ctx: ExtensionContext, balance: Balance): void {
  const color =
    balance.remaining <= CRITICAL_BALANCE_USD
      ? "error"
      : balance.remaining <= LOW_BALANCE_USD
        ? "warning"
        : "muted";
  ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg(color, `💰 ${usd(balance.remaining)}`));
}

function clear(ctx: ExtensionContext): void {
  ctx.ui.setStatus(STATUS_KEY, undefined);
}

/**
 * Refresh and render the balance. `provider` defaults to the active model's
 * provider so callers reacting to a model change can pass the incoming
 * provider before `ctx.model` has caught up.
 */
async function refresh(
  ctx: ExtensionContext,
  options: { force?: boolean; provider?: string } = {},
): Promise<Balance | undefined> {
  // No footer to update (and nothing will read the return value) outside
  // TUI/RPC, so skip the render *and* the network call that feeds it.
  if (!ctx.hasUI) return undefined;

  const provider = options.provider ?? ctx.model?.provider;
  if (provider !== PROVIDER) {
    clear(ctx);
    return undefined;
  }

  const now = Date.now();
  if (!options.force && cached && now - cached.fetchedAt < CACHE_TTL_MS) {
    render(ctx, cached.balance);
    return cached.balance;
  }

  const apiKey = await ctx.modelRegistry.getApiKeyForProvider(PROVIDER);
  if (!apiKey) {
    clear(ctx);
    return undefined;
  }

  const balance = await fetchBalance(apiKey, ctx.signal);
  if (!balance) return undefined;

  cached = { fetchedAt: Date.now(), balance };
  render(ctx, balance);
  return balance;
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    await refresh(ctx, { force: true });
  });

  pi.on("model_select", async (event, ctx) => {
    await refresh(ctx, { force: true, provider: event.model.provider });
  });

  pi.on("turn_end", async (_event, ctx) => {
    await refresh(ctx);
  });

  pi.registerCommand("credits", {
    description: "Show OpenRouter credit balance",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;
      if (ctx.model?.provider !== PROVIDER) {
        ctx.ui.notify("Active provider is not OpenRouter", "info");
        return;
      }
      const balance = await refresh(ctx, { force: true });
      if (!balance) {
        ctx.ui.notify("Could not fetch OpenRouter credit balance", "error");
        return;
      }
      ctx.ui.notify(
        `OpenRouter: ${usd(balance.remaining)} remaining (${usd(balance.usage)} used of ${usd(balance.total)})`,
        "info",
      );
    },
  });
}
