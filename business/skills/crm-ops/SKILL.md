---
name: crm-ops
description: >
  Use whenever the user wants to create, update, search, link, or otherwise operate on records in your CRM through
  its MCP or API - companies, contacts, deals, work orders / projects, contracts, invoices, or any custom object.
  Triggers on: "create deal", "update deal", "new work order", "create invoice", "log invoice", "add company to the
  CRM", "create contact", "find company in the CRM", "search the CRM for", "link this to the deal", "move deal to
  won", "vytvoř deal", "uprav deal", "nový work order", "vytvoř fakturu", "přidej firmu do CRM", "najdi v CRM",
  "propoj to s dealem", "/business:crm-ops". Enforces a tool-agnostic CRM operating discipline: search before create
  (dedupe by a natural key), required vs auto-managed fields, confirm the exact write payload before any create or
  update, never hand-edit auto-managed / auto-synced fields, link and relationship integrity, consistent record
  naming, and post-write output discipline. For loading ambient project context (status, gate checks) use
  `/common:context-pull`; for issue-tracker updates use `/common:jira-update`. The concrete object and field
  catalogue for your CRM lives in `assets/CRM_OBJECTS.md` (you maintain it).
---

# CRM Operating Discipline

Help the user operate their CRM correctly through whatever interface the client has wired up - an MCP server, a REST
or GraphQL API, or a CLI. The interface exposes generic create / read / update / link operations on records; **this
skill is the disciplined operating layer on top of it.** It is not tied to any CRM vendor: it captures the
transferable *patterns* that keep records clean, linked, and reportable, regardless of which product is underneath.

> **The client wires their own CRM.** This skill assumes the client has connected their CRM (any commercial product
> or a bespoke system - it does not matter which) via its own MCP or API, and has filled in `assets/CRM_OBJECTS.md`
> with the actual objects, fields, required/auto-managed flags, and naming conventions of that instance. Treat that
> file as the source of truth for *what* the fields are; treat this skill as the source of truth for *how* to write
> them safely.

## Object / field reference

The concrete catalogue - one table per object listing each field, whether it is required, whether it is
auto-managed, and any notes - is **`assets/CRM_OBJECTS.md`**, maintained by the client. **Read it before any create
or update operation.** If a field, object, or required flag is not in that file, do not guess it: ask the user or
inspect the live schema first, then update the reference.

Keep `CRM_OBJECTS.md` current. If the CRM's schema changes (new field, renamed key, new status), refresh the file by
inspecting the live schema through the MCP/API, because a stale reference causes silent write errors.

## Reasoning order

Before calling the CRM, run this sequence every time. If the request is tied to a project or gate check, load
ambient context first via `/common:context-pull` before proceeding.

1. **Identify the object(s)** the user is touching. If the request implies more than one (e.g. "new client" →
   Company + Contact + maybe Deal), enumerate them all.
2. **Read `assets/CRM_OBJECTS.md`** for each object. Pay particular attention to any **key-vs-label mismatch** the
   client has flagged - many CRMs expose an API key (slug/field id) that differs from the UI label, and writing to
   the wrong key is a silent failure or writes the wrong field.
3. **Distinguish the two tiers of "required":**
   - **Schema-required** - the CRM itself rejects the write if the field is missing. Hard gate.
   - **Policy-required** - required by the client's own convention to keep reporting and linking usable, but *not*
     enforced by the CRM. This skill must enforce these on the user's behalf.
   Both must be satisfied before any write.
4. **Detect missing inputs** - required fields the user has not supplied. Ask for them in a single batch, not
   field-by-field. Pre-fill whatever the conversation or existing records already tell you.
5. **Search before you create.** Dedupe against a **natural key** before creating any record (e.g. a contact by
   email, a company by domain or registration number). Always search first; if a match exists, use it instead of
   creating a duplicate.
6. **Validate links.** Confirm that every record you intend to link to (company, deal, contract, work order) exists
   by id before linking. If a dependency is missing, create it first, in the correct dependency order (see below).
7. **Apply the naming convention** from `CRM_OBJECTS.md`. Record names should be consistent and unique so records are
   findable - typically an `Organization — short description` style. Keep it the same across all records of a type.
8. **Never write to auto-managed fields** (see below). The interface will usually *accept* such a write - the
   guardrail is in this skill, not in the CRM.
9. **Confirm before write.** Surface the exact payload - object, each field key and value, and every link - in one
   message and ask the user to confirm. If the interface has its own approval gate, that is a second, independent
   gate; both serve a purpose.

## Search before create (dedupe)

Duplicates are the most common and most damaging CRM data error: they split history, break reporting, and confuse
everyone. Every object has a **natural key** that should be unique - define it per object in `CRM_OBJECTS.md`.
Before any create:

1. Search by the natural key (email, domain, registration number, an external reference id).
2. If exactly one match - use it.
3. If multiple matches - stop and ask the user which record is correct (or whether they need merging) rather than
   guessing or creating yet another.
4. Only if there is no match do you create.

## Link and relationship integrity

Records are only useful when correctly connected. Create dependencies in the right order so links never dangle:

- A contact must belong to a company before (or as) it is created - no orphan contacts.
- A deal links to its company (and to the relevant contacts).
- A downstream delivery record (project / work order) links to its company, its originating deal, its contract, and
  its invoices.
- An invoice links back to its company, its delivery record, and its contract.

If a target of a link does not yet exist, create it first, then link. After a multi-record operation, walk the chain
and confirm there are no orphans and no half-built links. Record exactly which relationship keys connect which
objects in `CRM_OBJECTS.md` - link keys are a frequent source of mismatched-label errors.

## Auto-managed fields - never hand-edit

Some fields are **owned by an upstream system** and must never be set by hand, even when the interface allows it.
Typical categories (the client lists the exact fields in `CRM_OBJECTS.md`):

- **Auto-enriched** - data the CRM populates from external enrichment (logo, company size, social handles,
  last-interaction timestamps, connection strength, AI summaries).
- **Workflow-managed** - figures a CRM workflow computes (rolled-up hours, costs, revenue, profit, budget flags).
- **Integration-synced** - fields kept in step with an external system (e.g. invoice amount / status / dates synced
  from a billing or accounting system once an external id has been set).

The interface will frequently report these as writable - **the guardrail is here, not in the CRM.** Refuse a user
request to set one of them; instead surface the *upstream* fix:

- A wrong synced invoice figure → fix it in the source billing system and let the sync re-run.
- Wrong rolled-up hours → fix the linked time entries / source records and wait for the rollup.
- A wrong computed figure (profit, revenue) → fix its inputs (expenses, linked source records); the workflow
  recalculates.

## Output discipline

After any successful create or update, tell the user, concisely:

1. **What changed** - the object, the record name, and which fields were touched.
2. **The record link** - a direct link or id for each affected record.
3. **Any follow-up the user owes** - e.g. "communicate the project code to the delivery team so their time syncs",
   "upload the signed contract to your document store", "move the invoice to *requested* when ready to bill". Make
   ownership of the next step explicit.

## Integration

- **`/common:context-pull`** — load ambient project/gate context before a CRM operation when the request is tied to
  an active project or deal.
- **`/common:jira-update`** — after a CRM change that warrants an issue-tracker update (e.g. deal won, project
  created, contract signed), use `/common:jira-update` to keep the issue tracker in sync.

## Pre-flight checklist

Before declaring a task done, verify against `CRM_OBJECTS.md`:

- Every contact is linked to a company (no orphans).
- Every active company has its relationship/status field and an owner set where the convention requires it.
- Every delivery record has its company, deal, contract, and invoice links.
- Any shared key that must reach another team (e.g. a project code that downstream time-tracking depends on) is set
  and communicated.
- Records follow the naming convention.
- No manual writes landed on any auto-managed field, even where the interface allowed them.
- Natural-key dedupe was run before every create.
