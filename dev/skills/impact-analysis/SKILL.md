---
name: impact-analysis
description: |
  Map the downstream blast radius BEFORE changing shared code, an interface, a contract, or a schema. Finds every
  dependent (direct and transitive), flags client-visible and contract surfaces, and lists the tests that exercise
  the change. Language-agnostic and analysis-only — it never modifies code; it reports so you can scope the change
  and decide risk first.

  English triggers: "what depends on", "what will break if I change", "impact of modifying", "downstream of",
  "blast radius", "before I rename this", "before I change this interface", "who calls this", "/dev:impact-analysis"

  České spouštěče: "co závisí na", "co se rozbije když změním", "dopad změny", "co je závislé na", "jak velký zásah",
  "než přejmenuju", "než změním toto rozhraní", "kdo to volá", "analýza dopadů", "/dev:impact-analysis"
---

# Impact Analysis

Analyze downstream impact **before** modifying shared code, a public interface, a data contract, or a schema.
Identifies every affected dependent, every contract/client-visible surface, and the tests that exercise them, so you
can make an informed decision about the scope and risk of a change.

**This skill does not make changes — it only analyzes and reports.** Run it before any structural change to something
others depend on.

## When to use

Trigger on any of:

- "what depends on `<symbol / module / table>`?"
- "what will break if I change `<function / field / column>`?"
- "impact of modifying `<shared component>`"
- "before I rename `<field>`"
- "before I change this interface / contract / schema"
- Any structural change to a shared module, public API, exported type, event/message shape, or database schema with
  known dependents.

## How to run

### Step 1 — Identify the target

Pin down exactly what is changing:
- The **target** — module / function / type / interface / endpoint / event / table / column.
- The **change kind** — rename, signature change, type change, behavior change, removal, storage-shape change. The
  kind drives how far you must trace (a rename traces *references by name*; a behavior change traces *callers that
  rely on the behavior*).
- The **surface class** — is the target **internal**, a **shared/internal-API** boundary, or a **public/contract**
  surface (consumed by other services, other teams, or external clients)? This drives the risk weighting in Step 4.

### Step 2 — Build the dependency graph

Map everything that depends on the target, directly and transitively. Use whatever the project already provides, in
order of preference:

1. **Project-provided lineage / dependency tooling** — if the repo or its build system can emit a dependency or call
   graph (build-graph queries, module-graph exports, IDE/LSP "find references", a pre-generated lineage map), use it.
   It is faster and more complete than text search.
2. **Static reference search** — otherwise, grep/search for imports, calls, and references to the target across the
   relevant packages. For monorepos, detect the package boundaries first and search each affected package.
3. **Cross-repo / cross-service** — if the target is a published contract (API, event schema, shared package version),
   the dependents may live in *other* repositories or services. Note these as **out-of-tree dependents** that this
   analysis cannot fully resolve from the current repo, and list the consumers you know of so they can be checked
   separately.

For each dependent record: name, location (path / module / service), whether it depends **directly** or
**transitively**, and — for column/field/parameter renames — whether it references the changed name *specifically*
(read the dependent's source to confirm; a graph edge alone does not prove the renamed member is used).

### Step 3 — Flag client-visible & contract surfaces

Walk the dependency chain and flag every surface that crosses a trust or ownership boundary:

- **Public API / contract** — endpoints, exported types, published package members, event/message schemas consumed
  outside this codebase.
- **Client-visible** — anything an external client, another team, or another service observes (response shapes,
  field names, enum values, error codes, file/report formats).
- **Persisted shape** — schema/columns that downstream stores, reports, or dashboards read.

For each flagged surface note **who owns / consumes it** and mark it **high risk** if a consumer is outside your
control (external client, another team's service, a contract you cannot unilaterally change).

### Step 4 — List affected tests

Identify the tests that exercise the target or any downstream dependent: unit tests on the target, integration tests
across the dependents, contract/schema tests, and any reconciliation or end-to-end tests that assert the
client-visible surfaces from Step 3.

Use the project's test-coverage tooling if it exposes a mapping; otherwise scan the test directories for references
to the target and its dependents. Note any dependent that has **no test coverage** — that is itself a risk finding.

### Step 5 — Produce the impact report

```
## Impact Analysis: <target>

### Target
- **Target:** <name> (<kind: module / interface / endpoint / event / table / column>)
- **Change kind:** <rename / signature / behavior / removal / ...>
- **Surface class:** <internal / shared-internal / public-contract>
- **Location:** <path / module / service>

### Downstream Dependents (<count>)
| Dependent | Location | Direct? | Uses changed member? |
|-----------|----------|---------|----------------------|

### Client-Visible / Contract Impact
| Surface | Type (API / event / schema / report) | Consumer | Owner | Risk |
|---------|--------------------------------------|----------|-------|------|

(none) — if nothing in the chain crosses a boundary.

### Out-of-Tree / Cross-Service Dependents
- <consumer not resolvable from this repo> — <how to verify separately>

(none) — if the target is internal-only.

### Affected Tests (<count>)
- <test type>: <test name> on <dependent>

### Risk Assessment
- **Scope:** <X> dependents affected, <Y> cross a client-visible/contract boundary.
- **Coverage gaps:** <dependents with no test coverage>.
- **Recommendation:** <what to run/check after the change; whether to coordinate with consumers first;
  whether a deprecation/migration window is needed for contract surfaces>.
```

## Edge cases and failure modes

- **No dependency tooling available** — fall back to static reference search, but state explicitly that the graph is
  search-derived and may miss dynamic dispatch, reflection, string-keyed lookups, or runtime-wired calls.
- **Member-level impact** — when renaming a field/column/parameter, graph or import edges are not enough: read each
  dependent's source to confirm whether it references the specific member by name. Whole-symbol dependency tools
  rarely track member-level usage.
- **Dynamic / reflective references** — calls resolved at runtime (reflection, string keys, config-driven dispatch,
  serialization by field name) won't show up in a static graph. Call these out as **unverifiable** rather than
  assuming zero impact.
- **Cross-repo contract change** — when the target is a published contract, the full blast radius extends beyond this
  repo. Surface that explicitly and list known consumers; do not imply the in-repo dependents are the whole picture.
- **High-risk client-visible change** — always surface to the human before proceeding. Do not treat a contract or
  client-visible change as routine; recommend coordinating with the consumer/owner first.

## Why this skill exists

Changes to shared code and contracts cascade silently. A rename or a type change in a low-level module can break a
consumer two services away that no one remembers depends on it. This skill makes the full blast radius visible
**before** any change is made — and it makes no changes itself.
