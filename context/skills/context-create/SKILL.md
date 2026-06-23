---
name: context-create
description: Build a navigation index (a "router" page) for a team or company's knowledge — a structured page that points to where information actually lives across their tools (wiki, drive, repos, CRM, data systems). Use this whenever someone wants to set up, bootstrap, or assemble an AI-readable context index, knowledge map, or navigation page; when onboarding a new team or company so an AI assistant knows where to find things; or when they have an audit or assessment document listing departments and systems and want to turn it into a usable index. Triggers on phrases like "build the context index", "set up our knowledge map", "create the navigation page", "make a rozcestník", "help the AI find our docs", "postav kontext", "vytvor rozcestník / index", "naštartuj index", "zostav navigačnú stránku", "urob mapu kde čo je". Run by the person who will own and maintain the index.
---

# Build a context index

This skill assembles a **navigation page** — one place that tells an AI assistant *where* a team's information lives, so it can find the right document, system, or dataset on demand.

Two ideas govern everything below:

1. **The index points, it does not store.** Every entry is a link plus one short sentence — never a copy of the content. This keeps the page small, keeps it from going stale, and lets each source system control who may open a given link.
2. **The index is a TREE OF ROUTERS, and only ONE link ever crosses up a level.** A thin **central index** links to per-project / per-area **sub-indexes**; each sub-index is its own router for its own detail. A single project's detail (its components, portal, data, support…) belongs on *that project's* sub-index — and only one line about it ever reaches the central index. If you ever find a project's internal sections sitting on the central page, the level was mis-classified.

> **The failure this skill exists to prevent:** pointing at one project's space (with a weak overview) and pouring that whole project's detail straight onto the central index — turning the company map into one messy project. **Phase 0 makes that impossible.** Do it first, every time.

---

## Phase 0 — Classify & Route (ALWAYS FIRST, before any interview, build, or write)

You were pointed at *something* — a Confluence space, a Drive folder, a discovery doc, a URL, or just "our whole company". Before building anything, work out **what it is** and **which level its content belongs at**. Three steps.

### Step A — Open and look (ignore the name)
Actually fetch the source: list the space's pages / the folder's files / read the document. The name ("DLApp", "ATI", "whole company") tells you *nothing* — classify from contents. **Classify by the OPENED source, never by the owner's label.** If the owner says "whole company" but the source is plainly one project, the source wins (you will say so out loud in Step C).

A link that won't open is a **wrong or dead link to flag now** — you the builder have access. (Access-denied-is-normal applies only later, at runtime, to other users.)

### Step B — Classify on two axes

**KIND — what is this?**
- **PROJECT/AREA** — one product, project, team, client, or department. Tell-tale: everything inside is about *the same one thing* (Components, Portal, Data, Support all belong to the same product). DLApp and ATI are both PROJECT/AREA.
- **COMPANY-INVENTORY** — spans many *independent* areas/projects/departments. Tell-tale: a discovery/assessment/onboarding doc listing departments + systems, OR a top space whose children are themselves whole projects/departments.
- **PILE-OF-FILES** — a folder/dump with no organizing overview.
- **OTHER/UNKNOWN** — doesn't fit. Stop and ask one clarifying question rather than guess.

> **Multi-product tie-break (the soft cell):** if the children are themselves *whole products/teams* → it's COMPANY-INVENTORY, recurse into each. If *all* children serve ONE product → it's PROJECT/AREA. "A big space" is not the same as "many projects" — judge by what the children *are*, not by page count.

**SHAPE — does it navigate itself?**
- **SELF-NAVIGATING** — the landing/home already links onward to its own main sub-parts (e.g. an ATI home that links to its Pipedrive deals, SOW, project diary, sub-pages). Countable test: from the home, **most of its main sub-areas are reachable in 1–2 clicks**.
- **WEAK/EMPTY** — the overview is missing, thin, a bare title, or just a wall of undifferentiated detail (DLApp). It does not navigate itself.
- **Partial → treat as WEAK/EMPTY.** If the home links to only some of its sub-areas, do not call it self-navigating; build/improve its landing.

### Step C — State the verdict out loud, then route
Before doing anything else, say it back in one line and wait for confirmation:

> "This looks like a **{KIND}** that is **{SHAPE}**, so I'll **{ROUTE}**, and its content belongs **{as a sub-index linked from the central index / as the central skeleton}**. I will *not* pour its detail onto the central index."

If the stated scope and the source conflict, name it explicitly: *"You said whole-company, but this source is a single project, so I'll build its sub-index and add one line to the central index."*

### The routing table (the load-bearing artifact)

| KIND | SHAPE | ROUTE | Where the content lands |
|---|---|---|---|
| PROJECT/AREA | self-navigating | **link-only** | ONE line in the central index → the existing landing. Do not mirror. *(ATI case.)* |
| PROJECT/AREA | weak/empty | **create-subindex** | Build a sub-index FOR THAT PROJECT on its OWN page; add ONE line to the central index. *(DLApp case — the one the old skill got wrong.)* |
| COMPANY-INVENTORY | any | **create-central** | Build the thin central skeleton: top sections + ONE entry per project/area + `needs link` placeholders. Detail pushed down to sub-indexes. |
| PILE-OF-FILES | any | **break-down** | Curated sub-index (handful of meaningful docs by topic + one fallback link to the folder); ONE line in central → that sub-index. |
| OTHER/UNKNOWN | — | **ask, then re-run Phase 0** | — |

> **HARD INVARIANT.** `create-central` is reachable **ONLY** from COMPANY-INVENTORY. A single project/space/area can **NEVER** take route `create-central`. If you are about to write **more than ~one line about a single project** onto the central index, you mis-classified — **stop and re-run Phase 0.**

---

## Get the build/write URL(s) — always ask

Whatever the route, you must know **which page each result is written to**. **Always ask the owner.** Never infer a location from `context__get_index` — that runtime tool returns the index *content only*, never a location, so it cannot tell you where to write.

- **link-only / create-central** need **one** URL: the central index page.
- **create-subindex / break-down** need **two** URLs: (1) the sub-index's own page, and (2) the central index page that gets the single up-link.

**If no central index exists yet (bootstrap):** do **not** improvise by making the project the central index — that is the exact failure. Create a **stub central index** (top sections + the one line linking to this sub-index) alongside the sub-index. The owner can grow the central skeleton later by running the skill on a company inventory.

For each URL, read its current content and branch:
- **Empty / brand-new** → build it.
- **Has content** → **Edit mode**: don't start over. Walk what's there, work out what's missing / wrong-sectioned / duplicated / stale, **propose only the additions/changes**, and **get the owner's OK before writing**. Never edit silently.

---

## Run the route

### Route: create-subindex (PROJECT/AREA, weak/empty) — *the App fix*
1. Build a sub-index **for this project, on its OWN page**. Group its real docs by what they *are* (Planning, Research, Commercial, Reference, Components, Portal, Data, Support…), each a pointer with one sentence. **All** the per-project detail lives here.
2. Add **exactly ONE line** to the central index: `[Project (System)](sub-index url) — one sentence.`
3. **Mixed-space tie-break:** if the project space also contains genuinely *company-wide* pages (a glossary, org-wide policies, cross-team standards), classify by the **dominant** content (it's still PROJECT/AREA) — but **pull each cross-cutting page UP to the central index as its own one-line entry** in the right section. Don't bury company-wide pages inside the project sub-index, and don't leave the project's own detail on central.

### Route: link-only (PROJECT/AREA, self-navigating) — *the KTI case*
The target already routes itself. Add **ONE line** in the right central section pointing at that landing. **Do not** mirror or rebuild it, and do not create a sub-index page for it.

### Route: create-central (COMPANY-INVENTORY only)
Build the **thin skeleton** on the central URL: top-level sections (e.g. Company / Engineering / Data / Business — match how the org actually thinks) + **ONE entry per project/area**, with `needs link` placeholders where unknown. **Detail never lives here.** For each area that is itself a project/space/folder, **re-run Phase 0 on it** to decide link-only vs create-subindex vs break-down. Recursion terminates at link-only / break-down leaves, and at plain inline entries for small areas (a 2–3-system area can stay one line rather than getting its own page).

### Route: break-down (PILE-OF-FILES)
On a sub-index URL, list the handful of meaningful docs grouped by topic + one fallback link to the whole folder. Never mirror every file. Add ONE line in central → this sub-index.

---

## Entry format & description rules (all routes)

```
[Name (System)](link) — one short, direct sentence about what's there.
```

- The system name in parentheses says where it lives.
- **Write each description from the OPENED source, not from memory.** Open the link, base the sentence on real content. A link that won't open is a wrong/dead link to **flag**, not to write a guess around.
- **Known system, no link yet** → still add the entry and mark `needs link`. That shows the owner exactly what's left.
- **No owner / access / sensitivity fields.** The source system enforces access when someone follows the link; a refusal is normal, not a broken link. The index is a map, not an access-control list. Never paste content from behind a login.
- **Give each top-level section a one-line intro** so a reader knows what it's for at a glance.
- **Don't write the page's purpose header.** The standard top blurb (what the page is, "navigation not storage", read via the context tool) is **template boilerplate** — same for every deployment, lives in the index scaffold, **not produced by this skill.** Leave it untouched and untranslated; only add/adjust the content sections below it.

---

## Idempotent — don't churn

Re-running on unchanged sources must produce the **same** result. In Edit mode, propose only additions / moves / fixes; never rewrite or drop existing entries; save only after the owner approves. A clean index stays clean. Two specific don'ts: don't re-explode a project, and don't duplicate a project's single central line.

**Remediating an already-exploded central index:** if the central page already carries a single project's internal sections (the old failure), the fix is a one-time move — propose lifting that detail onto the project's sub-index and collapsing it to one central line. Show the move, get the OK, then apply it.

---

## Write the result
Always **preview → get the OK → save**, in every route. Keep the same shape every time so the index stays predictable.

A complete, generic illustration of the finished shape — a **thin central index + one sub-index it links to**, plus the classification cheat-sheet and a WRONG-vs-RIGHT contrast — is in `example.md`. **Read it before assembling** so the output matches.
