# Zero personal instructions

Global guidance applied in every workspace (ahead of each project's `AGENTS.md`).

## Escalation for `op` and `gh`

The 1Password CLI (`op`) and GitHub CLI (`gh`) talk to host-level state that
Zero's sandbox hides: `op` reaches the 1Password desktop app via its group
container socket, and `gh` authenticates using envvars/secrets provided by
`mise`/`op`.

When these commands fail inside the sandbox (`operation not permitted`, 401 /
bad token, "op can't reach the desktop app"), rerun them with
`sandbox_permissions: "require_escalated"` and a short justification, using a
narrow `prefix_rule` such as `["op"]`, `["gh"]`, or `["git", "push"]` when a
reusable approval is appropriate. Prefer `with_additional_permissions` (network
or filesystem) when that alone satisfies the command instead of full
escalation.

`op read`/`op run` pulls secrets from the `Private` vault (e.g.
`op://Private/GH CLI PAT`, `op://Private/Exa API Key`) for `mise` envvars.
`sandbox.additionalWriteRoots` in the global config can persist write roots;
command escalation itself is per-command and always interactive — request it
only when the sandboxed attempt actually fails.
