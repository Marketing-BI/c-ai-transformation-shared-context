# Monorepo Package Boundaries

## Package Structure

- Each package has a single, well-defined responsibility. Name packages by domain or capability, not by technical layer.
- Every package declares its own dependencies explicitly — never rely on a sibling's or the root's dependencies being
  hoisted into scope.
- Each package exposes a public API through one well-defined entry point. Internal modules must not be imported directly
  from outside the package.

## Dependency Direction

- Shared libraries (types, utilities, UI primitives) are leaf dependencies — they must not import from application
  packages.
- Application packages (services, apps) may depend on shared libraries and on each other's public APIs, never on each
  other's internals.
- No circular dependencies between packages. Enforce the boundary and the direction with tooling, not convention alone.

## What Goes in Shared Packages

- Types and contracts shared across two or more applications.
- Validation rules reused on more than one side of a boundary (e.g., by a client and a server).
- The shared UI component library / design-system primitives.
- Utility functions used in multiple packages.
- Constants, enumerations, and error codes shared across services.

## What Stays in Application Packages

- Business logic specific to one service or app.
- Entry points, request handlers, controllers, and views.
- Service-specific configuration.
- Data migrations and seed data.

## Creating a New Package

- Must be justified: the code is needed by two or more consumers, or the package enforces a clear boundary.
- Follow the existing naming and structure conventions of the monorepo.
- Register it in the workspace configuration and verify it builds independently.
- Never create a package for a single utility — add that to an existing shared package instead.
