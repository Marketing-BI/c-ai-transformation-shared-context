# CRM Object Reference (client-maintained)

This is a **template**. Fill it in with the real objects, fields, and conventions of *your* CRM instance, then keep
it current. `crm-ops` reads this file before every create or update, so an accurate, up-to-date reference is what
keeps writes safe. Placeholders are written as `«…»` - replace them.

> **How to fill this in.** Inspect your CRM's live schema through its MCP or API (list the objects, then list each
> object's fields). For every field record: its API key, whether it is required, whether it is auto-managed, and any
> note. When the schema changes, refresh this file - it is not auto-synced.

## Column meaning

Each object below has one table with these columns:

- **Field** - the human label.
- **Key** - the API key / slug / field id used when writing. **This may differ from the label** - record both, and
  call out any surprising mismatch in *Notes*; writing to the wrong key is a silent failure.
- **Required?** - `schema` (the CRM rejects the write without it), `policy` (your own convention requires it but the
  CRM does not enforce it), or `—` (optional).
- **Auto-managed?** - `yes` if an upstream system owns this field (enrichment, a workflow, or an external sync) and
  it must **never** be hand-edited; `—` otherwise. See the *upstream fix* note for how to correct an auto-managed
  value.
- **Notes** - link direction, allowed values, the natural key, gotchas.

## Conventions (fill in)

- **Natural keys (for dedupe).** Per object, the field you search on before creating, so you never make a duplicate:
  - `«Company»` → `«domain / registration number»`
  - `«Contact»` → `«email»`
  - `«…»` → `«…»`
- **Naming convention.** How record names are formed, kept consistent and unique:
  - `«Deal»` → `«Organization — short description»`
  - `«Contract»` → `«Organization — contract type»`
  - `«Delivery record»` → `«Organization — project description, period»`
- **Dependency / link order.** The order records must be created so links never dangle:
  `«Company» → «Contact» → «Deal» → «Contract» → «Delivery record» → «Invoice»` (adjust to your model).
- **Shared keys that must reach another team.** Any key a downstream team depends on (e.g. a project/order code that
  time tracking must reference): `«key»` → who must receive it and why.

---

## Worked example structure - `«Company»`

This block shows the *shape* to copy for every object. Replace every `«…»` with your instance's real values; the
field names below are illustrative placeholders, not real fields from any product.

**Object key:** `«company_object_key»`  ·  **Natural key (dedupe on):** `«domain»`  ·  **Owner:** `«role»`

| Field | Key | Required? | Auto-managed? | Notes |
|-------|-----|-----------|---------------|-------|
| `«Name»` | `«name_key»` | policy | — | Commercial name; part of the naming convention |
| `«Domain»` | `«domain_key»` | policy | — | **Natural key** - search before create; used for enrichment + dedupe |
| `«Relationship / status»` | `«status_key»` | policy | — | Allowed values: `«…»`, `«…»`, `«…»` |
| `«Registration number»` | `«reg_number_key»` | — | — | Needed before contracts |
| `«Owner»` | `«owner_key»` | — | — | Set when the relationship is active |
| `«Primary contact»` | `«contact_link_key»` | — | — | Link → `«Contact»` (multi). **Label may differ from key** - verify |
| `«Logo / enrichment»` | `«enriched_key»` | — | **yes** | Auto-enriched - never hand-edit |
| `«Last interaction»` | `«interaction_key»` | — | **yes** | Auto-tracked - never hand-edit |

**Auto-managed - upstream fix:** to correct `«enriched_key»` / `«interaction_key»`, fix it `«in the enrichment
source / let the tracker re-run»`, not by hand.

**Common mistakes (fill in):** `«missing status»`, `«no owner on an active customer»`, `«missing natural key breaks
dedupe»`, `«hand-editing an auto-managed field»`.

---

## `«Contact»`

**Object key:** `«contact_object_key»`  ·  **Natural key (dedupe on):** `«email»`  ·  **Owner:** `«role»`

| Field | Key | Required? | Auto-managed? | Notes |
|-------|-----|-----------|---------------|-------|
| `«Name»` | `«…»` | policy | — | |
| `«Email»` | `«…»` | policy | — | **Natural key** - unique; search before create |
| `«Company»` | `«…»` | policy | — | Link → `«Company»`. Every contact must link to a company - no orphans |
| `«Role / title»` | `«…»` | — | — | |
| `«…»` | `«…»` | — | **yes** | Auto-enriched / auto-tracked - never hand-edit |

---

## `«Deal»`

**Object key:** `«deal_object_key»`  ·  **Naming:** `«Organization — short description»`  ·  **Owner:** `«role»`

| Field | Key | Required? | Auto-managed? | Notes |
|-------|-----|-----------|---------------|-------|
| `«Name»` | `«…»` | schema | — | Follow the naming convention |
| `«Stage»` | `«…»` | schema | — | Pipeline: `«…»` → `«…»` → `«won»` / `«lost»` |
| `«Owner»` | `«…»` | schema | — | |
| `«Value»` | `«…»` | policy | — | **In the client's invoicing currency** - do not assume a default |
| `«Company»` | `«…»` | policy | — | Link → `«Company»` |
| `«Contacts»` | `«…»` | policy | — | Link → `«Contact»` (multi) |
| `«Source»` | `«…»` | — | — | For funnel analytics; allowed values `«…»` |

---

## `«Delivery record»` (project / work order)

**Object key:** `«delivery_object_key»`  ·  **Naming:** `«Organization — project, period»`  ·  **Owner:** `«role»`

| Field | Key | Required? | Auto-managed? | Notes |
|-------|-----|-----------|---------------|-------|
| `«Title»` | `«…»` | schema | — | Follow the naming convention |
| `«Project / order code»` | `«…»` | schema | — | **Unique.** Shared key - communicate to the delivery team if time tracking depends on it |
| `«Owner»` | `«…»` | schema | — | |
| `«Pricing model»` | `«…»` | schema | — | Allowed values `«…»` |
| `«Stage»` | `«…»` | schema | — | `«new»` → `«in progress»` → `«done»` |
| `«Company»` | `«…»` | policy | — | Link → `«Company»` |
| `«Deal»` | `«…»` | policy | — | Link → `«Deal»` |
| `«Contract»` | `«…»` | policy | — | Link → `«Contract»` |
| `«Invoices»` | `«…»` | policy | — | Link → `«Invoice»` (multi) as invoices are created |
| `«Rolled-up hours»` | `«…»` | — | **yes** | Workflow-managed from linked time entries - never hand-edit |
| `«Computed revenue / profit»` | `«…»` | — | **yes** | Workflow-computed - never hand-edit; fix the inputs instead |

---

## `«Contract»`

**Object key:** `«contract_object_key»`  ·  **Naming:** `«Organization — contract type»`  ·  **Owner:** `«role»`

| Field | Key | Required? | Auto-managed? | Notes |
|-------|-----|-----------|---------------|-------|
| `«Name»` | `«…»` | schema | — | Follow the naming convention |
| `«Status»` | `«…»` | schema | — | `«draft»` → `«under review»` → `«signed»` |
| `«Type»` | `«…»` | schema | — | Allowed values `«…»` |
| `«Currency»` | `«…»` | schema | — | |
| `«Company»` | `«…»` | policy | — | Link → `«Company»` |
| `«Signed document»` | `«…»` | — | — | Set when signed; also store the file per your convention |
| `«Delivery record»` | `«…»` | — | — | Link → `«Delivery record»` once it exists |

---

## `«Invoice»`

**Object key:** `«invoice_object_key»`  ·  **Natural key (dedupe on):** `«external id»`  ·  **Owner:** `«role»`

| Field | Key | Required? | Auto-managed? | Notes |
|-------|-----|-----------|---------------|-------|
| `«Title»` | `«…»` | schema | — | |
| `«Requested amount»` | `«…»` | schema | — | |
| `«Currency»` | `«…»` | schema | — | |
| `«Status»` | `«…»` | schema | — | Manual up to `«requested»`; auto after that (see below) |
| `«Company»` | `«…»` | policy | — | Link → `«Company»`. **Verify the key matches the label** |
| `«Delivery record»` | `«…»` | policy | — | Link → `«Delivery record»`. **Verify the key matches the label** |
| `«Contract»` | `«…»` | policy | — | Link → `«Contract»` |
| `«External id»` | `«…»` | — | — | The key that enables the billing-system sync once set |
| `«Amount / dates / status»` (post-sync) | `«…»` | — | **yes** | Synced from the billing system after the external id is set - never hand-edit |

**Auto-managed - upstream fix:** correct synced invoice values in `«the billing system»` and let the sync re-run.

---

## Cross-object integrity checklist (fill in for your model)

- [ ] Every `«Contact»` links to a `«Company»` (no orphans)
- [ ] Every active `«Company»` has its status field and owner where the convention requires
- [ ] Every `«Delivery record»` has its `«Company»`, `«Deal»`, `«Contract»`, `«Invoice»` links
- [ ] Every shared key (`«project/order code»`) is set and communicated to the right team
- [ ] Every `«Contract»` links to a `«Company»`
- [ ] Every `«Invoice»` links to `«Company»`, `«Delivery record»`, `«Contract»`
- [ ] No manual writes to any auto-managed field, even where the interface allows them
- [ ] Natural-key dedupe was run before every create
