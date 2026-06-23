---
name: context-create
description: Build a navigation index (a "router" page) for a team or company's knowledge — a structured page that points to where information actually lives across their tools (wiki, drive, repos, CRM, data systems). Use this whenever someone wants to set up, bootstrap, or assemble an AI-readable context index, knowledge map, or navigation page; when onboarding a new team or company so an AI assistant knows where to find things; or when they have an audit or assessment document listing departments and systems and want to turn it into a usable index. Triggers on phrases like "build the context index", "set up our knowledge map", "create the navigation page", "make a rozcestník", "help the AI find our docs", "postav kontext", "vytvor rozcestník", "naštartuj index". Run by the person who will own and maintain the index.
---

# Build a context index

This skill helps assemble a **navigation page** — one place that tells an AI assistant *where* a team's information lives, so it can find the right document, system, or dataset on demand.

The single most important idea: **the index points, it does not store.** Every entry is a link plus one short sentence, never a copy of the content. This keeps the page small, keeps it from going stale, and means each source system still controls who may open a given link.

## First — load the current index

Before anything else, load the index that already exists for this deployment, so you know whether you're **creating it fresh** or **extending an existing one**. Offer the person two ways to load it (let them choose — don't guess):

- **A) The `context__get_index` tool** (preferred). This is the deployment's own runtime MCP tool that returns the configured index automatically — it reads the index location from the deployment config, so nobody types a URL. Use it whenever `context__get_index` is available in the session.
- **B) A URL** (fallback). If that tool isn't available, ask the person for the index page URL and read it directly.

Then look at what came back and branch:

- **Empty / not found / first time** → go to **Create** (start from an audit if one exists, otherwise the interview below).
- **Already has content** → go to **Edit**: do **not** start over. Walk what's already there, work out what's missing, wrong-sectioned, duplicated, or stale, and **propose only the additions/changes**. Show the proposal and **ask the owner's permission before writing anything** — never edit the index silently.

## Start from an audit if one exists

If the user has a discovery document, assessment, onboarding doc, or project definition that already lists their departments and systems, **read it first and pre-fill the structure from it.** Building from an existing inventory beats asking from a blank page — the interview then becomes confirming and filling gaps rather than starting over.

If there's no such document, run the short interview.

## Create — the interview

Keep it to three plain questions (the person answering is usually not technical). The index is a **tree**: scope → areas → where each lives.

1. **Scope — who is this index for?** The whole company, or one team/department? This sets the **top-level sections** (whole company → e.g. `Company`, `Dev`, `Business`, `Data`; one team → just that team's sections).
2. **Areas — what are the main buckets under that?** The projects, departments, or topics someone would look *under*. Give examples so it's concrete: *"under Company, things like Projects, People, Strategy; under Dev, things like Repositories, Architecture."* Each area becomes a section or, if it's big, its own **sub-page**.
3. **Where each area lives — which system + a link.** For every area, which tool holds it and the link (Confluence space, Drive folder, GitLab group…). This becomes the entries. Each linked target should ideally have **its own overview/landing** so navigation cascades — see *Link to a target, or break it down?*

Deliberately don't ask about access, owners, or sensitivity — see *Why we don't ask about access*.

## Assemble the page

**Top-level sections** group the index — for example by team (Engineering, Data, Business) plus a cross-cutting section for company-wide things (projects, strategy, people). Use whatever divisions match how the organization actually thinks.

**Nest, don't flatten.** When an area or project has more than a handful of entries, give it its **own sub-page** and link to it from the top, instead of listing everything on one page. The top page stays short and scannable, and the assistant opens a sub-page only when it needs that branch. This is what lets the index scale to many projects and documents without turning into a wall of links.

**Entry format** — keep every entry to three visible parts:

```
[Name (System)](link) — one short, direct sentence about what it is.
```

The system name in parentheses tells the reader where it lives. Keep descriptions brief and concrete. If a system clearly belongs in the index but has no link yet, still add the entry and mark it as needing a link — that shows the owner exactly what's left to fill in.

**Write each description from the source, not from memory.** Before writing an entry's one-line description, **open the link and base the sentence on what's actually there** — don't guess. The person building the index has access to these systems, so a link that won't open is almost always a **wrong or dead link** — flag it and fix the link, don't invent a description around it. (Access-denied being "normal" applies *later, at runtime*, when different users open the finished index — not now, while you the owner are building it.) The same first-hand check applies when deciding whether a target needs breaking down — see the next section.

**Give each top-level section a one-line intro** (e.g. *"Cross-cutting: projects, strategy, people."*) so a reader knows what the section is for at a glance.

Don't add fields for who owns it, who can access it, or how sensitive it is. The index is a map, not an access-control list.

**Don't write the page's purpose header.** The standard top blurb that says *what the page is* — a navigation router, "navigation not storage", read by the AI through the context tool — is **template boilerplate**, the same for every deployment. It is **not produced by this skill**: it lives in the index template/scaffold. Leave it untouched (and untranslated); only add/adjust the content sections below it.

## Link to a target, or break it down?

When an entry points at something that itself contains many things, decide by asking *does the target navigate itself?*

- **It has its own landing/overview** that explains what's inside (e.g. a well-kept wiki space) → just link to that one page and let it be the next level of navigation. Don't copy its contents.
- **It's a pile of files** with no overview (a shared-drive folder, a dump) → **break it down**: list the handful of meaningful documents grouped by what they're about, plus one fallback link to the whole folder. Never mirror every file, and never copy their contents.
- **Its landing page is empty or useless** → the best fix is to give it a real landing page first, then link to that.

## Why we don't ask about access

The index only ever holds pointers, so it's safe to list even a sensitive system — the link is just a signpost. When someone follows a link, the source system checks their own login and decides: it opens for people who have access and refuses everyone else. Access is therefore enforced where it belongs, at the source, and the index never needs to know or store who can see what. A refusal is normal and expected, not a broken link. The one thing never to do is paste actual content from behind a login into the index.

## Write the result

**Always preview, always get the OK before saving** — in both flows.

- **Create:** assemble and write the pages — the top index page, plus a sub-page for each area/project that needs one. Show a preview, let the user adjust wording, then save.
- **Edit:** apply only the proposed additions/changes to the **same index location** it was loaded from; never rewrite the whole page or drop existing entries. Show what will change (added / moved / fixed) and save only after the owner approves.

Keep the same shape every time so the index stays predictable.

A complete, generic illustration of the finished shape is in `example.md` — read it before assembling so the output matches.
