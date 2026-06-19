# Development Practices

## Third-Party Libraries

- Search for an existing solution in the codebase before adding a new dependency.
- Evaluate a dependency before adding it: maintenance activity, adoption, footprint, license, and security advisories.
  Prefer dependencies with few or no transitive dependencies when alternatives exist.
- Pin exact versions in the manifest (no floating ranges) and rely on a lockfile for deterministic installs.
- Audit dependencies regularly and address critical and high-severity vulnerabilities promptly.
- When removing a dependency, verify nothing else still references it.
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

## Scope Discipline

- **Think before coding** — understand the problem and the existing code first; know what you are changing and why before writing a line.
- **Simplicity first** — choose the simplest solution that fully solves the problem; prefer straightforward solutions over complex architectures, and don't add abstractions or generality you don't need yet (YAGNI).
- **Surgical changes** — touch only what the task requires; don't refactor, rename, or reformat unrelated code.
- **Goal-driven execution** — keep the stated goal in view and stop when it is met; don't gold-plate or expand scope unprompted.

## Code Changes

- Always read existing code before suggesting modifications. Understand the context first.
- Prefer editing existing files over creating new ones.
- Match the existing code style of the file you're editing.
- When generating code, make it production-ready — no placeholder comments.
- Use planning before changes that span several files or involve architectural decisions; get the plan approved first.

## Architecture Boundaries

- Keep layer boundaries intact and one-directional (for example, transport → application/service → data access); a
  layer never reaches around the one beneath it.
- Keep services stateless — no in-memory locks, caches, or mutable shared singletons that assume a single instance.
- Validate every input at the system boundary before it reaches business logic; stricter validation is better than
  lenient.
