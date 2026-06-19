---
name: testing-conventions
description: |
  Auto-load when reading, creating, or modifying test files of any kind: unit tests, integration
  tests, end-to-end tests, test fixtures, test factories, test helpers, mock/stub files, or test
  runner configuration. Applies wherever test code lives — co-located with source, in a dedicated
  test directory, or in a shared testing library.

  English triggers: "test", "spec", "unit test", "integration test", "E2E test", "end-to-end test",
  "test fixture", "test factory", "mock", "stub", "test setup", "test coverage", "test isolation",
  "TDD", "red-green-refactor", "/dev:testing-conventions"

  České spouštěče: "test", "spec", "unit test", "integrační test", "E2E test", "end-to-end test",
  "testovací fixture", "továrna pro testy", "mock", "stub", "nastavení testů", "pokrytí testy",
  "izolace testů", "TDD", "červená-zelená-refaktor", "/dev:testing-conventions"

  Do NOT apply when: writing production code that will later be tested (use the relevant domain
  convention skill instead), refactoring production code for testability without touching test
  files, or running tests to verify existing behavior without editing test files.
---

# Testing Conventions

## Approach

- **TDD**: write tests first when the requirement is clear. Red → Green → Refactor.
- Test behavior, not implementation.
- Test at the right level: integration tests for components that primarily orchestrate; unit tests for complex isolated logic.

## What to Test

- Business logic and data transformations (service/domain layer)
- Edge cases and boundary conditions
- Error-handling paths
- Multi-tenant data isolation (tenant/scope ID filtering)
- Permission and access-control enforcement

## What NOT to Test

- External libraries (they have their own tests)
- Barrel re-export files with no logic
- Default values (unless critical to business logic)
- Simple getters/setters with no logic
- Framework internals and decorator mechanics
- Generated code (schema types, protocol buffer types, etc.)
- Transport-layer handlers that contain no logic beyond delegating to a service
- Repository/data-access classes that contain no logic beyond data retrieval

## Testing Discipline

- Ban `.skip` and `.only` in committed code. Use `.todo` for planned tests; enforce the ban in CI.

## Test Organization

- Co-locate unit/integration tests next to the source file they test.
- File naming pattern: `<module>.spec.<ext>` (unit), `<module>.i.spec.<ext>` (integration), `<module>.e2e.spec.<ext>` (E2E).
- E2E tests live at the application level in an `e2e/` directory.
- Shared test utilities (factories, helpers, constants) belong in a dedicated testing library, not scattered across modules.

## Test Isolation

- **Data store**: use a dedicated test data store with transaction rollback per test. Do not mock the data store or repository layer in service-level integration tests.
- **Cache**: flush test keys in `beforeEach`; use namespaced keys to prevent cross-test pollution.
- **Time**: use fake/controlled timers for time-dependent logic.
- **IDs**: override ID generation with deterministic sequences for reproducible tests.
- **Mock cleanup**: clear all mocks globally in `afterEach` to prevent test pollution.
- **Parallel safety**: tests must be independent — no shared mutable state between tests.
- Each test creates its own isolated scope (e.g., tenant context) — never share state between tests.
- Never use real names, email addresses, or PII in test fixtures.

## Test Data Patterns

- **Builder/factory pattern**: fluent API for constructing complex test entities with sensible defaults.
- **Factory composition**: create related entities together through factories.
- **Deterministic seeding**: seed random data generators for reproducible test data.
- **Cleanup**: data-store transactions roll back automatically; cache keys are flushed in `afterEach`.

## Unit Tests

- Scope: a single function or method in isolation.
- Mock all dependencies (data-access layer, external services).
- Mock at service boundaries only — never mock internal methods.
- Assert mock calls with expected arguments, not just invocation count.
- Focus: business logic, edge cases, error handling.

## Integration Tests

- Scope: multiple layers working together (service + data-access + data store).
- Use a test data store with transactions that roll back after each test.
- Focus: data flow, correctness of execution paths, access-control enforcement, locking and conflict behavior, cross-service calls.

## E2E Tests

- Run with a browser/client automation tool separate from unit/integration test runners.
- Focus: critical user journeys, authentication flows, navigation, critical data visualization.

## Coverage Enforcement

- Set minimum coverage thresholds per service or module (e.g., 70% line coverage, 60% branch coverage).
- Enforce thresholds in CI — do not allow coverage regressions without explicit review.

## Test Naming Convention

- Describe block: `ComponentName.methodName` format.
- Test names: start with "should", describe expected behavior clearly.
- Include context in the name: "when a valid ID is provided", "when the user does not exist".

## Bug Fix Requirements

- Every bug fix must include automated tests in the same change that fixes the bug.
- Tests must reproduce the bug condition before the fix is applied.
- Tests must pass after the fix is applied.
