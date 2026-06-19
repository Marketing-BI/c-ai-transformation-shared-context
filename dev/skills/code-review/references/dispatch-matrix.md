# Dispatch matrix — which reviewer for which change

Pick reviewers by what `SCOPE_FILES` actually contains. Each `subagent_type` is the plugin-qualified `dev:` agent
name. Dispatch the selected set **in parallel** (one message, multiple `Agent` calls). When in doubt about a
borderline file, include the reviewer — a clean "Approved" is cheap; a missed issue is not.

Signals below are **language-agnostic** — match on the *role* of the file (what it does), not on any one stack's
file extensions or framework names.

| The diff touches… (neutral signals) | Dispatch |
| --- | --- |
| Any non-trivial code change | `dev:code-reviewer` |
| Comments or API/doc-comments added or changed | `dev:comment-reviewer` |
| Error handling, try/catch or equivalent, logging, fallbacks, async/concurrency primitives | `dev:error-handling-reviewer` |
| New or changed logic that should be covered by tests | `dev:test-coverage-reviewer` |
| Data access, loops over IO, list/query endpoints, transactions, render- or compute-heavy paths | `dev:performance-reviewer` |
| Backend / service code: route handlers, controllers, services, modules, data access, integrations, server config | `dev:backend-architect` |
| Frontend / UI code: views, components, client-side state, client routing, app/bundler config | `dev:ui-architect` |
| Public API surface: REST/HTTP routes, API schema/spec, GraphQL or RPC schema/resolvers, request/response contracts (DTOs) | `dev:api-doc-reviewer` |
| Auth, secrets, new endpoints, PII / sensitive data flows, external boundaries, multi-tenant access control | `dev:security-reviewer` |
| Architecture- or system-design-level change (new service, cross-service boundary, major restructuring) | `dev:solution-architect` |
| There is a solution / acceptance-criteria doc to verify coverage against | `dev:business-case-evaluator` |

## Notes on overlap

The reviewers have deliberately separate lanes — dispatching several together is expected, and they hand off to each
other rather than duplicate:

- `dev:code-reviewer` does line-level bugs/quality; it hands error handling, comments, perf, security, and design to
  the specialists. Don't drop it just because specialists run — it's the only general bug sweep.
- `dev:performance-reviewer` covers runtime smells in the diff; `dev:backend-architect` covers architecture-level
  scalability, and `dev:solution-architect` covers cross-service/system design. They won't double-count.
- `dev:business-case-evaluator` is only useful when a requirements/solution doc exists to check against — skip it
  otherwise.

## Minimal vs full

- A tiny, single-file logic change → often just `dev:code-reviewer` (+ `dev:test-coverage-reviewer` if it added logic).
- A backend feature touching endpoints, data access, and auth → `dev:code-reviewer`, `dev:backend-architect`,
  `dev:error-handling-reviewer`, `dev:performance-reviewer`, `dev:api-doc-reviewer`, `dev:security-reviewer`,
  `dev:test-coverage-reviewer`.
- A whole-branch review before a PR/MR → select per the table across all changed files.
