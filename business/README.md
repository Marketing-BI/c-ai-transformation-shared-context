# business plugin

Shared AI context for the **business / commercial team**: a generic CRM operating discipline, interactive document
generators, and customer-intelligence and sales-call coaching. Everything here is tool- and vendor-agnostic - the
team wires its own CRM, transcription tool, and calendar underneath.

## Skills

| Skill | What it does |
|---|---|
| **`/business:crm-ops`** | A tool-agnostic CRM operating discipline: search-before-create (dedupe by a natural key), required vs. auto-managed fields, confirm the exact write payload before any create/update, never hand-edit auto-managed fields, link/relationship integrity, consistent naming, and post-write output discipline. The team connects its own CRM (any product or a bespoke system) via that CRM's MCP or API and fills in `assets/CRM_OBJECTS.md`. |
| **`/business:sow`** | Drafts a **Statement of Work** through an interactive interview and writes a complete markdown file with YAML frontmatter, ready for branding. Positions the supplier as a confident advisor, not an order-taker. |
| **`/business:brief`** | Drafts a **Business Brief** (the internal analytical artifact behind a SOW) through a senior-business-analyst discovery interview - business context, problem, stakeholders, requirements, data/integration needs, risks, assumptions, open questions - and judges SOW readiness. Honest about what is unknown (`[OPEN]` / `[ASSUMPTION]`); never fabricates. |
| **`/business:prospector`** | **ICP / customer-intelligence research**: discovers where a target audience talks online, extracts their exact pain language, scores severity (frequency x emotional intensity), separates buyers-ready from venters, and synthesizes an Ideal Customer Profile plus an engagement strategy. The market/positioning layer - use it for positioning, messaging, targeting, or sharpening an ICP. |
| **`/business:sales-coach`** | **Per-call** discovery/sales coaching in three modes: **PRE** (research + ICP-fit + pre-call brief), **VIDEO** (a personalized pre-call video script), and **POST** (transcript debrief + scorecard against tracked weaknesses + two follow-up email drafts + a recommendation). Built on a tactical discovery script layered over an open-ended discovery philosophy. |

## How they fit together

- **`sow` and `brief` output markdown.** To turn either into a branded `.docx`, run `/common:branding-docx`
  afterwards. The `brief` is the internal analysis that feeds and refines a `sow`.
- **`prospector` builds the ICP; `sales-coach` uses it.** `prospector` is the market-level research that defines who
  to sell to; `sales-coach` is the per-call layer that scores a specific prospect against that ICP. If a request names
  a specific call or person, it belongs to `sales-coach`, not `prospector`.
- **`crm-ops` keeps the record clean.** `sales-coach` reads and updates prospect/deal records through it.

## Cross-plugin dependencies

- `/common:branding-docx` - converts `sow` / `brief` markdown into the branded deliverable.
- `/common:context-pull`, `/common:jira-update` - referenced by `crm-ops` for ambient context and issue-tracker
  updates.
