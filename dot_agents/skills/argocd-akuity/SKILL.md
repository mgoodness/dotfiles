---
name: argocd-akuity
description: >
  Command surface for the `argocd` and `akuity` CLIs — Argo CD application management and
  Akuity-hosted Argo CD/Kargo instance/cluster lifecycle. Use when an agent needs to list, get,
  sync, or diff Argo CD applications; create, export, or upgrade an Akuity-managed instance or
  cluster; or decide whether a task belongs on these CLIs versus Akuity's hosted MCP endpoint.
---

# argocd / akuity: CLIs, Not MCP

Two separate CLIs cover this surface. `argocd` talks to a single Argo CD instance's own API server (or, with `--core`, straight to Kubernetes) and owns day-to-day application lifecycle: list, get, sync, diff. `akuity` talks to the Akuity Platform API and owns everything above a single instance: creating/upgrading instances and clusters, exporting whole instance specs, and the same lifecycle for Kargo. Prefer both over Akuity's hosted MCP endpoint — not out of habit, but because three concrete jobs below are structurally impossible over MCP, and everything else about these CLIs (structured output, scriptable exit codes, non-interactive auth) fits an agent's context-efficiency needs better than a browser-OAuth'd HTTP tool call does anyway.

## Why CLI, not MCP

Akuity's `agent-plugins` repo is a thin client shim pointing Claude Code/Codex at a closed-source, hosted MCP server (`akuity.cloud/mcp`) — not an open-source MCP implementation itself. That plugin's own onboarding skill states the CLI is required, not optional, for three jobs:

- **Live-credential cluster-agent installs** (`akuity argocd cluster install-agent`) — streams manifests containing live credentials straight into `kubectl`; an HTTP MCP tool has no local `kubectl` to stream into.
- **Any Secret- or credential-bearing apply** — the MCP endpoint refuses `argocd-secret` / repository-credential / `kargo-secret` manifests by design. The CLI (or the Akuity UI or Terraform) is the only path for these, full stop.
- **Full/filtered instance export** (`akuity argocd export`) and **instance version listing** (`akuity argocd instance versions` / `akuity kargo instance versions`) — no MCP read returns either.

Beyond those three hard gaps, prefer these CLIs for ordinary work too: JSON/YAML output an agent can parse directly, documented exit codes a script can branch on without model involvement, and env-var auth that doesn't need a browser. Reach for the MCP endpoint only for its one capability neither CLI has: Akuity's native AI-agent delegation (On-call Agent, Deployment Agent, Promotion Advisor conversations) — out of scope here.

## `argocd`: single-instance application lifecycle

Auth: `argocd login <server>` interactively, or non-interactively via `--auth-token` / `ARGOCD_AUTH_TOKEN`. `--core` bypasses the Argo CD API server and talks straight to Kubernetes when running with cluster access — no MCP equivalent, since the hosted server has no local kubeconfig.

Command surface relevant to an agent:

```
argocd app list [-o json|yaml|wide|name] [-p PROJECT]
argocd app get APPNAME [-o json|yaml|wide|tree]
argocd app create APPNAME --repo ... --path ... --dest-server ...   # upsert by name
argocd app set APPNAME --parameter key=value
argocd app unset APPNAME --parameter key
argocd app sync APPNAME [--dry-run] [--async]
argocd app diff APPNAME [--local PATH]
argocd app manifests APPNAME
argocd app resources APPNAME [--orphaned] [-o tree]
argocd app delete APPNAME
argocd proj ...
argocd repo ...
argocd cluster ...
```

- `-o json|yaml` on `app list`/`app get` returns full Application objects (`metadata`/`spec`/`status`) — see "Structured output and exit codes" below.
- `app diff` documents its own exit-code contract verbatim: **2 on general errors, 1 when a diff is found, 0 when no diff is found**. Branch on this in shell (`if argocd app diff foo; then ...`).
- `app sync --dry-run` previews without side effects; `--async` returns immediately instead of blocking on completion. Default to `--dry-run` first for anything an agent initiates unsupervised.
- `app create` is an upsert by `APPNAME` — safe to re-run; `app set`/`app unset` mutate an existing app's parameters directly.

## `akuity`: platform-level instance/cluster lifecycle

Auth: `akuity login` (browser OAuth against `--server`, default `https://akuity.cloud`), or non-interactively via `AKUITY_API_KEY_ID`/`AKUITY_API_KEY_SECRET`. This authenticates against the Akuity Platform API — a different backend from the per-instance Argo CD/Kargo API servers `argocd`/`kargo` talk to directly.

```
akuity argocd instance create|update|delete|list|get|versions
akuity argocd cluster create|update|delete|list|get|upgrade|install-agent|get-agent-manifests
akuity argocd apply -f MANIFESTS [--prune all|apps|appprojs|appsets|clusters|cmps|managed-secrets|repo-credentials|...]
akuity argocd export --organization-name NAME INSTANCE
akuity argocd diff -f MANIFESTS
akuity argocd addon ...
akuity kargo instance|agent|apply|export|diff ...   # same shape, for Kargo instances
akuity organization ...
akuity whoami
```

- `akuity argocd apply` is the declarative, prune-capable entry point for whole instance specs — and, per the credential boundary below, the only path (besides the UI/Terraform) for anything Secret-bearing.
- `akuity argocd export` dumps a whole instance spec; pipe through `yq`/`jq` to filter (e.g. `akuity argocd export --organization-name <org> <instance> | yq 'select(.kind == "ArgoCD") | .spec...'`). This is the substitute for the "no MCP read returns the full manifest" gap above.
- `akuity argocd instance versions` / `akuity kargo instance versions` (`-o json|yaml|wide`) list installable product versions — the substitute for the "no MCP tool lists versions" gap.
- `akuity argocd cluster install-agent` streams agent manifests with live credentials straight into `kubectl apply` — the substitute for the credential-streaming gap; nothing else installs a cluster agent.

## Structured output and exit codes

Both CLIs default to human-readable output; always pass `-o json` (or `yaml`) when the result feeds back into agent reasoning or a script, rather than parsing the default table/wide format. Prefer a documented exit-code contract (`app diff`'s 0/1/2) over output-parsing wherever one exists — it's branchable without invoking the model at all.

## The credential/secret boundary

Both MCP endpoints refuse Secret-bearing manifests (`argocd-secret`, repository-credential `Secret`s, `kargo-secret`) by design — not a gap to route around, a security boundary. `akuity argocd apply`/`akuity kargo apply` (or the Akuity UI, or Terraform) are the only paths for these.

## Common Mistakes

- **Parsing output instead of using `-o json` or the documented exit-code contract** — see "Structured output and exit codes" above.
- **Skipping `--dry-run` on an agent-initiated `app sync`** — default to a preview first for anything not explicitly supervised.
- **Reaching for MCP for a Secret-bearing apply, a cluster-agent install, an instance export, or a version listing** — all four are CLI-only; see "Why CLI, not MCP" above.
- **Confusing which CLI owns which layer** — `argocd` is single-instance application lifecycle; `akuity` is platform-level instance/cluster lifecycle (plus the same for Kargo). Reach for `akuity instance`/`cluster` subcommands, not `argocd`, for anything above a single application.

## Completion criterion

An agent can, without prompting: list/get/sync/diff an Argo CD application via `argocd` with structured output and the documented exit-code contract; create/export/list-versions an Akuity-managed instance or cluster via `akuity`; and correctly route any Secret-bearing apply, cluster-agent install, instance export, or version-listing task to the CLI rather than MCP.
