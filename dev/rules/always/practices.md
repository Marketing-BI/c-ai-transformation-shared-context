# Development Practices

## Third-Party Libraries

- Wrap a third-party library that is used across many files behind a thin abstraction (one or two files) so the
  underlying library can be swapped in a single place.
- Name that abstraction for its purpose, not its implementation (e.g., a `translation` module, not one named after the
  library that powers it).

## Error Handling

- Never expose internal errors to clients — log the full detail on the server side and return a safe, generic message
  to the caller.
- Fail fast on programmer errors and unrecoverable states; handle expected, recoverable failures deliberately at the
  boundary where they arise.

## Configuration

- Supply all configuration through the environment, not hardcoded in source.
- Critical configuration values must have no default — a missing one is a startup failure, never a silent fallback.
- Validate all required configuration once at startup and fail fast if anything is missing or malformed.
- Never read raw environment values throughout the code — access configuration through a single typed, validated
  accessor.

## Architecture Boundaries

- Keep layer boundaries intact and one-directional (for example, transport → application/service → data access); a
  layer never reaches around the one beneath it.
- Keep services stateless — no in-memory locks, caches, or mutable shared singletons that assume a single instance.
- Validate every input at the system boundary before it reaches business logic; stricter validation is better than
  lenient.
