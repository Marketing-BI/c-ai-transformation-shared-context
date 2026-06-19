# Coding Standard

## Core Rules

- **Meaningful names.** Names state intent — what a thing is or does, not how it is implemented. No abbreviations that
  aren't established in the domain, no single letters outside tight loops, no encoding the type into the name.
- **Immutability by default.** Treat values and the data passed across boundaries as immutable; reach for a mutable
  binding only when you genuinely need to reassign. Do not mutate arguments a caller still owns.
- **Make illegal states unrepresentable.** Model the domain with the type system so that an invalid state cannot be
  constructed in the first place, instead of guarding against it after the fact.
- **Explicit over clever.** Prefer the obvious form a reader understands at a glance over the terse or "smart" one.
  Make the public contract of a unit explicit at its boundary (inputs, outputs, and what it can fail with).
- **Handle absence explicitly.** Represent "no value" with the language's intended mechanism (option/nullable/result),
  and deal with it deliberately at the point it arises — never force or ignore it to silence the compiler.
- **Small, focused units.** One function or type does one thing. If you need a paragraph to explain what it does, or a
  conjunction to name it, split it.
- **No dead or duplicated code.** Remove unused code rather than commenting it out — version control is the history.
  Each piece of knowledge lives in exactly one place; extract a shared definition instead of copying logic.
- **No magic values.** Every literal (number, string, duration, limit, default) that carries meaning becomes a named
  constant. Search for an existing constant before introducing a new literal.
- **Resolve async work deliberately.** Never leave asynchronous work unawaited or its result unhandled — every
  concurrent operation is either awaited, composed, or has its failure explicitly routed.
- **Fail loudly, not silently.** Surface errors and unexpected states at the boundary where they occur. Do not swallow
  exceptions, ignore returned errors, or paper over a failure with a fallback that hides it.

## Naming Conventions

- Pick one convention per identifier kind (files, types, constants, functions, variables) and apply it uniformly across
  the codebase; follow the idiomatic casing of the language in use.
- Names read consistently — the same concept has the same name everywhere it appears.
- A name describes the role, not the underlying technology or library that happens to implement it.

## Single Source of Truth

- Never duplicate a constant or type that already exists. Always search before defining a new one.
- No hardcoded values: before using any literal (string, number, duration, limit, default), look for an existing
  constant to reuse.
- Put reusable defaults and shared constants in a shared module — never scatter copies of the same default across
  service code.

## Formatting

- Let the language's standard formatter own layout — indentation, line breaks, quote style, import ordering. Do not
  argue these by hand or in review; configure the tool once and let it decide.
- Keep imports/includes grouped and ordered the way the formatter or linter dictates, separating standard-library,
  third-party, and local groups.
