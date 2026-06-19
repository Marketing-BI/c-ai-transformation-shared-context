---
name: backend-conventions
description: |
  Auto-load when working on server-side or API code — controllers, services, handlers, route/endpoint
  definitions, middleware, guards, filters, interceptors, request/response DTOs, health-check configuration,
  or a server entry point. Also applies to any code whose primary responsibility is an HTTP boundary,
  module wiring, or application-layer orchestration.

  English triggers: "backend", "API endpoint", "service layer", "controller", "handler", "route",
  "middleware", "request validation", "error filter", "health check", "rate limit", "caching layer",
  "server config", "/dev:backend-conventions"

  České spouštěče: "backend", "API endpoint", "vrstva služeb", "kontrolér", "handler", "routa",
  "middleware", "validace požadavku", "obsluha chyb", "health check", "rate limiting", "cachování",
  "konfigurace serveru", "/dev:backend-conventions"

  Do NOT apply when: working on UI/frontend code, editing shared utility code with no HTTP or service
  responsibility, performing database schema/migration work only, or editing test files only.
---

# Backend / Service-Layer Conventions

## Module & Layer Structure

- One module per domain concept.
- **Transport layer** (controllers / route handlers): HTTP concerns only — parse the request, call the application layer, return the response. Zero business logic.
- **Application/service layer**: business logic lives here. Calls the data-access layer for persistence.
- **Data-access layer**: encapsulates all queries and persistence operations. Services never write queries directly.
- Shared infrastructure connections (caches, message queues) must use a shared provider — never create duplicate connections per service.
- Never import code directly from other services — call their published endpoints.
- Use dedicated request/response objects (DTOs, input types, value objects) for request/response validation. Never expose data-access entities directly to API consumers.

## RESTful API Design

- Use plural nouns with dashes: `/users`, `/project-users/:id`, `/plan-templates`.
- Action defined by HTTP method: GET (read), POST (create), PUT (replace whole resource), PATCH (partial update), DELETE (remove).
- Query parameters for filtering, sorting, pagination: `?status=active&sort=-createdAt&page=2`.

## API Versioning

- Use URL-prefix versioning: `/v1/users`, `/v2/users`.
- Support at most two active versions simultaneously.
- Signal deprecation with `Deprecation` and `Sunset` HTTP response headers.
- Breaking changes require a new version. Additive changes (new fields, new endpoints) do not.

## Pagination

- All list endpoints must be paginated.
- Prefer cursor-based pagination over offset-based.

## Idempotency

- All mutation endpoints (POST, PUT, PATCH, DELETE) must be idempotent.
- Use idempotency keys for operations that modify state.
- The same request repeated multiple times must produce the same result with no duplicate side effects.

## Rate Limiting

- Implement rate limiting on all endpoints.
- Apply stricter limits to expensive operations (imports, bulk updates, report generation).
- Use a distributed cache backend for rate-limit counters when running multiple service instances. Document the chosen backend and any deviations in project CLAUDE.md.

## Caching

- Use the cache-aside pattern: check cache → miss → fetch from store → populate cache → return.
- Cache layers (ascending TTL): in-process memory (short TTL) → distributed cache (longer TTL) → data store.
- Set explicit TTLs on all cache entries — never cache indefinitely.
- Invalidate on write: when data changes, invalidate related cache keys immediately.
- Cache keys must include tenant/scope identifiers to prevent data leakage across tenants.
- Log cache hit/miss ratios for observability.

## Health Checks & Observability

- Every service must expose a `/health` (or equivalent) endpoint for readiness probes.
- Health checks must verify critical dependencies (data store, cache, external APIs) — not just return a 200 status.

## Error Handling

All endpoints must route through a centralized error-handling layer (framework exception filter, error-handling middleware, or equivalent). Ad-hoc per-endpoint error formatting is not allowed — it breaks the global response contract.

### Unified Response Envelope

All endpoints return a `{ data, error }` envelope via the centralized layer:

- Success: `{ data: <payload>, error: null }`
- Failure: `{ data: null, error: <ErrorObject> }`

Error object fields:

- `code` — machine-readable error code from the shared error-code registry
- `message` — user-facing message, safe to display in any client
- `details` — developer context; included only in non-production environments
- `statusCode` — HTTP status code

### Caught Errors

When catching an error from a lower layer:

- Re-throw a standardized error object — never leak raw framework exceptions or data-store driver errors to the client.
- The standardized object must carry: logging-level details (stack, context), a client-safe message, and the HTTP status code.
- Never swallow errors silently — even expected failures must be logged at the appropriate level.

## Startup & Database Initialization

- Migrations run automatically before the service begins accepting requests.
- Fail-fast on startup: the service must exit if the data store, cache connection, or migration fails.
- Health checks verify connectivity before marking the service ready.

## Configuration & Data Retention

- All retention periods must be configurable via environment variables — no hardcoded durations.
- Soft-deleted records have a defined recovery window before hard deletion.

## Logging & Observability

- Use structured logging (JSON format) with consistent fields across all services.
- Required log fields: `timestamp`, `level`, `message`, `correlationId`.
- Log levels: `error` (broken), `warn` (degraded), `info` (business events), `debug` (development only).
- Never log sensitive data: passwords, tokens, PII.
- Log all data mutations for an audit trail (who, what, when).
