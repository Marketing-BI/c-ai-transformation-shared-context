---
name: database-conventions
description: |
  Auto-load when working on database schema definitions, migration files, SQL queries, seed files,
  or data-access layer code (repository classes, query builders, ORM entity definitions). Covers
  schema design, indexes, constraints, migrations, transactions, row-level security, and SQL style.

  English triggers: "database", "schema", "migration", "SQL", "query", "repository", "index",
  "constraint", "ORM", "entity", "seed file", "data model", "row level security", "transaction",
  "CTE", "join", "/dev:database-conventions"

  České spouštěče: "databáze", "schéma", "migrace", "SQL dotaz", "repozitář", "index", "omezení",
  "datový model", "seedovací soubor", "transakce", "CTE", "join", "řádková bezpečnost",
  "/dev:database-conventions"

  Do NOT apply when: working on frontend components or UI code, reading a schema only to understand
  a DTO shape for a frontend task, or modifying HTTP controllers that only call repository methods
  without touching queries or schemas.
---

# Database & SQL Conventions

## Design Principles

- Start normalized (3NF) — denormalize only when real performance data justifies it.
- Schema before code — model entities and relationships before writing migrations.
- Treat performance as a schema problem first — check indexes, partitioning, and covering indexes before adding caching layers.

## Schema Conventions

- Use a consistent primary key strategy — document the choice in project CLAUDE.md.
- Use timezone-aware timestamp types for all timestamp columns (never naive/local timestamps).
- Use unbounded text types over length-limited strings unless a hard length constraint is required.
- Use a structured/semi-structured column type (e.g., `jsonb`) for semi-structured data, but prefer normalized columns for fields that are queried.
- Represent enumerated domains as database enum types — never hardcode value lists in application code.
- Add NOT NULL constraints explicitly; add foreign keys and indexes to enforce referential integrity.

### Index Selection

- B-tree (default) — point lookups, equality, range queries.
- BRIN — only for naturally ordered columns (e.g., `created_at` on append-only tables).

## Transactions

- Never run CPU-bound or blocking operations (hashing, cryptography, file I/O) inside a transaction — they hold locks and block other queries.
- Pattern: validate and compute first → open transaction → write → close.
- Instantiate data-access objects with the transaction connection, not the root database client.
- Each migration runs in a transaction (auto-rollback on failure).

## Data-Access / Repository Pattern

- Encapsulate all queries in repository or data-access classes. Services never write queries directly.
- Avoid N+1 queries — use joins or batch loading.
- Pagination is required on all list endpoints; prefer cursor-based over offset-based.
- Filter in the `WHERE` clause, not in application code after loading.
- Never use `SELECT *`, especially when rows contain large structured columns.
- SQL-first: push as much work as possible into SQL (joins, aggregation, filtering) — avoid fetching data to process it in application code.

## Migrations

- Never modify an existing committed migration — create a new migration to fix issues.
- Always test rollback: the down migration must correctly reverse the up migration.
- Include data migrations in the same transaction as schema changes where possible.
- One logical change per migration file, with a descriptive name.

## Row-Level Security (RLS)

- Enable RLS on all multi-tenant tables.
- RLS policies act as a secondary defense (safety net), not the primary authorization layer.
- Test RLS policies explicitly — verify data isolation between tenants.

## Concurrency Control

- Use optimistic locking for concurrent edits — document the specific strategy in project CLAUDE.md.

---

## SQL Style

### General

- New lines are cheap; reader time is expensive — do not optimize for fewer lines.
- DRY: factor repeated logic into CTEs or shared views. The same logic in two places means two maintenance points.
- Be consistent and explicit.

### Naming Conventions

**Column names**
- All column names use `snake_case`.
- Ambiguous fields (`id`, `name`, `type`, `status`) must be prefixed: `account_id`, `user_name`, `order_type`.

**Booleans**
- Must start with `is_`, `has_`, or `does_`: `is_deleted`, `has_sla`.

**Timestamps and dates**
- Timestamps: `_at` suffix (always UTC).
- Dates: `_date` suffix.
- Truncated date columns: named after the truncation level (`_month`, `_week`).
- Never use bare `date` or `month` as column names.

### References and Aliases

- Prefer full table or CTE names over single-letter aliases.
- If a name is long, rename the CTE to something shorter — do not use `a`, `b`, `c` as aliases.
- Always qualify column references with the table or CTE name in joins, even when unambiguous.

### Joins

- Always use explicit join syntax (`INNER JOIN`, `LEFT JOIN`) — never comma-separated `FROM` with implicit joins.
- Use `ON` with explicit column references rather than `USING`.

### Common Table Expressions (CTEs)

- Prefer CTEs over subqueries — always.
- Declare all CTEs in a `WITH` block at the top of the query.
- Each CTE represents one logical unit of work.
- Add an empty line after the opening parenthesis and before the closing parenthesis:

```sql
WITH my_cte AS (

    SELECT
        column_1,
        column_2
    FROM source_table

)
```

### Aggregations

- List non-aggregated columns first, then aggregated columns.
- Never use `GROUP BY ALL` — list columns explicitly or use positional references (`GROUP BY 1, 2, 3`).

### Preferred Patterns

- `!=` over `<>`
- `WHERE` over `HAVING` when either would work
- `COALESCE` over warehouse-specific null-handling functions
- `CAST(x AS type)` for explicit type conversion
- `CASE WHEN ... END` for conditional logic (portable across SQL dialects)
- Always qualify column references with table/CTE in multi-table queries
- `DATE_TRUNC` for truncation; `EXTRACT` for date parts; avoid inline date arithmetic

### Commenting

- `--` for single-line comments; `/* */` for multi-line.
- Add brief descriptions to non-obvious calculations.
- No TODO comments in SQL — track outstanding work in the project issue tracker instead.
