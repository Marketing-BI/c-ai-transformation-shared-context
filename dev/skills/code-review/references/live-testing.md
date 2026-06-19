# Phase 2 — Live endpoint testing

Exercise the running API to catch what static review can't: 500s, auth gaps, validation holes, error-leakage. This
phase is **best-effort** — if any precondition fails, skip with a one-line note in the report and continue. Never
block the review on it, and **always kill processes you start.**

## When to run

Run only when: the scope is local (or a checked-out PR/MR) **and** the diff touches a runnable API surface (route
handlers, controllers, endpoints, resolvers, a gateway). Skip when: read-only environment, no clear way to start the
app, the app needs external services you can't provide, or there's no API surface in scope.

## Step 1 — Detect how to run the app

- Find the dev/start command from the project's own task definitions — its build/run manifest, task-runner config,
  container/compose file, or documented "how to run" instructions. Detect the toolchain from whatever lockfile,
  build descriptor, or runtime manifest is present, and use that toolchain's run command.
- If a project skill or `run` pattern exists for starting this app, prefer it.
- If you can't determine a start command, **skip** this phase.

## Step 2 — Start and wait for ready

- Start the app in the background. Poll its health/readiness endpoint (or the port) until it responds, with a timeout
  (e.g. ~60s). If it doesn't come up, capture the startup error as a finding and **skip the rest of Phase 2.**

## Step 3 — Discover the endpoints in scope

From `SCOPE_FILES` only (don't test the whole app). Identify the endpoints the changed files expose, however this
stack declares them — for example:

- **HTTP route handlers / controllers:** route or method declarations (annotations/decorators, a router table, or
  explicit registrations) in the changed files.
- **Generated / spec-driven routes:** the routes generated from the changed controllers or the API spec.
- **GraphQL / RPC:** the changed resolvers, schema fields, or service methods.

## Step 4 — Authentication

Most endpoints need auth. Use the project's documented test/dev account if one exists; otherwise **ask the user** for
a test credential (and project/tenant context). If none is available, test only the unauthenticated paths and note
the limitation.

## Step 5 — Exercise each in-scope endpoint

- **Happy path** — valid request → expected success.
- **Validation** — missing required fields, wrong types, empty strings, boundary values (0, negative, very large),
  oversized payloads → expect a proper 4xx, never a 500.
- **AuthN/AuthZ** — no token → 401; invalid/expired → 401; valid token wrong role → 403; wrong tenant/project → 403
  or empty (isolation).
- **Errors** — non-existent id → 404; malformed id → 400; duplicate (unique constraint) → conflict, not 500.
  Confirm responses never leak stack traces or internal details.
- **Edge** — special characters / injection probes in string fields, unicode, pagination extremes (`page=0`, `-1`,
  `pageSize=10000`).

## Step 6 — Record and clean up

- Record each failure as a finding: request (method, path, body), expected vs actual, severity (CRITICAL if 500 /
  stack-trace leak, HIGH if auth bypass, MEDIUM if validation gap, LOW if edge).
- **Kill every process you started** (the dev server and any children). Verify they're gone before leaving the phase.
