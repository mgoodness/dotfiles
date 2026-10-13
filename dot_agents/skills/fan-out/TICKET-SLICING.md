# Ticket slicing

The checks and worked examples behind `fan-out`'s step 1. That step carries the general
shape and the two collisions that gate a wave; this carries the rest.

## Further checks

Run these over the same frontier, once the two collisions in step 1 are clear.

1. **Shared verification resource.** Two tickets whose tests need the same port, temp path,
   fixture, or CI job name. Not a design collision, but they fight at the guardrail
   instead of at review.
   _Symptom:_ both tickets add a test against the same fixture.
2. **Discovery order.** A ticket whose _output is a decision_ — a spike, a prototype, a
   research read — that another ticket's design assumes. The decision lands first;
   everything downstream waits on it.
   _Symptom:_ a dependent ticket names a value the decision ticket has not settled.
3. **Self-sufficiency.** Each ticket must be implementable from its own text. One that
   needs its siblings read alongside it is not a tracer bullet — fold the context in.
   _Symptom:_ "as described in #<sibling>".
4. **Edge justification.** For every blocking edge, name what the blocked ticket needs and
   cannot do itself. Conceptual affinity is not a dependency.
   _Symptom:_ "this should probably go first", with no artefact to name.

## Worked examples

### Foundation collision — CI, linter, Dependabot

Three tickets: add a Go CI workflow; add `golangci-lint` with a config; add Dependabot.
The workflow and the lint config are one foundation — the workflow's lint job runs the
config — and both branches would edit `.github/workflows/ci.yml` and `go.mod`.

Widen the CI ticket to own the lint config, or make it block the lint ticket. Dependabot
touches only `.github/dependabot.yml`, so it rides parallel with the foundation.
**Wave: one foundation, then two in parallel** — not three.

### Undecided shared interface — who names the module

Two tickets each need a path for a new package, and neither they nor the spec name it.
Left alone, both branches invent `internal/overview` and collide in `go.mod`.

Widen the first to decide the path and record it, or add a one-line contract ticket that
both depend on. **Wave: one contract ticket, then two in parallel.**

### Discovery order — a spike another ticket assumes

One ticket is a spike establishing whether an API supports X. Another builds the cache that
assumes X is available. Landing the cache first means designing against a guess — and the
guess is invisible in the ticket text, so nothing flags it.

The spike blocks the cache. **Wave: one, then one.**

### Self-sufficiency — a ticket that needs its sibling

One ticket adds a parser, another adds the CLI flag that calls it, and the flag's text says
"wire it up as in the parser ticket". Neither can be worked alone, and the fan-out tab for
the second opens without the first's context.

Fold the surface into the flag ticket — the signature it calls, the error it returns — so it
stands alone. **Wave: two in parallel**, once each names its own surface.
