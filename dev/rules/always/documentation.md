# Code Documentation

## Guiding Principle

- Document the *why* and the public contract — not the *how* the code already shows.
- One good line beats an essay; no comment beats one that merely restates the code. Redundant documentation is a defect.
- Comments are part of the code: keep them truthful and current. A stale comment is worse than none — update or delete
  it when the code changes.

## File / Module Level

- Give every non-trivial file a short (1–3 line) doc comment stating its purpose and its role in the architecture.
- Link to the relevant architecture note or related component when it genuinely aids understanding.
- Skip files that carry no logic: pure re-export/aggregation files, generated code, fixtures, and tests.

## Public Functions, Methods, and Operations

- Document every exported/public unit with a brief description of *what* it does and *why* — omit the *how* when the
  body makes it obvious.
- Describe parameters and return values only when their names and types don't already convey intent.
- State what the unit can fail with (the errors or exceptional outcomes it surfaces).
- Add a short usage example for general-purpose utilities in shared modules.
- Document a private/internal unit only when its logic is non-obvious.

## Types and Interfaces

- State a type's purpose in one line when the name alone isn't enough.
- Document an individual field only when its name and type aren't self-explanatory. Skip the obvious ones.

## Inline Comments

- Explain *why*, never *what* — the code already shows what.
- Reserve them for the things code can't express: security rationale, performance trade-offs, and non-obvious design
  decisions.
- Do not embed ticket numbers, specification references, or external tracker links in source comments; record a
  deferred task with enough context to be actionable on its own.

## What NOT to Document

- Re-export/aggregation files, generated code, fixtures, and tests.
- Trivial accessors and self-evident units.
- Obvious null/absence checks and type narrowing.
