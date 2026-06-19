---
name: sow
description: >
  Drafts a Statement of Work (SOW) for a client engagement through an interactive interview, then writes a complete
  markdown file with YAML frontmatter ready for branding. Use whenever the user wants to create or draft a SOW, scope
  of work, scope document, engagement scope, or project scope - in any language. Triggers on: "SOW", "statement of
  work", "scope of work", "create SOW", "draft SOW", "prepare SOW", "project scope", "napsat SOW", "vytvořit SOW",
  "připravit SOW", "scope dokument", "napsat scope", "rozsah prací", "/business:sow". Outputs markdown only - to
  produce the final branded `.docx`, run `/common:branding-docx` afterwards. Do NOT use this to estimate effort or to
  update an already-delivered SOW (edit the markdown directly for that).
---

# Statement of Work Generator

Generate the **content** of a SOW as a markdown file through an interactive interview. Pairs with
`/common:branding-docx` for the branded `.docx` deliverable.

## Positioning and tone

Position the supplier as a **confident advisor**, not a vendor fulfilling orders. The SOW should read as a senior
consultant recommending a course of action, not as a list of what the client asked for. Use language like "We
recommend...", "The proposed approach...", "This engagement will establish..." rather than "As requested by the
client...".

**Writing style:** senior consultant. Professional, precise, authoritative. No contractions. Strategic use of
passive voice. Bold inline emphasis for key terms. Bullet points only when they genuinely improve clarity (e.g.
listing documentation deliverables) - default to prose paragraphs. NEVER use em dashes (`—`) anywhere - use regular
dashes with spaces (` - `), commas, parentheses, or restructure.

## Interactive workflow

Three phases. Between each, summarize what was captured and confirm with the user before proceeding. Use
`AskUserQuestion` where possible. Skip questions already answered by context (the conversation, a client project file
such as `.claude/PROJECT.md`, the issue tracker, the team wiki).

### Phase 1: Discovery

1. **Language** - in which language should the SOW be written? (English / Czech / other)
2. **Client** - company name, contact person name
3. **Supplier contact** - the engagement lead on your side (default: current user if known)
4. **Project overview** - free-form: what problem are we solving, what will we deliver?
5. **Existing context** - check for a client project file, issue-tracker items, wiki docs, meeting transcripts.
   Pre-fill what you can.

Summarize → confirm → proceed.

### Phase 2: Scope definition

Most important phase. Iterate with the user:

1. **Propose scope items** - based on the project overview, propose H2-level deliverables. Present for feedback.
2. **Refine each deliverable** - what specifically will be delivered? Where is the boundary? Sub-deliverables?
3. **Default inclusions** unless the user opts out:
   - **Documentation** - comprehensive technical documentation
   - **Knowledge Transfer / Handover** - walkthrough sessions, handover
4. **Out of scope** - proactively suggest exclusions. Defaults unless the user says otherwise:
   - **Support and SLA** (unless explicitly in scope)
   - **Third-Party Software Support**
   - **Client-Side Responsibilities** (internal training, business process redesign, vendor coordination)
   Cross-check against scope for contradictions. Flag conflicts to the user.
5. **Dependencies** - propose based on scope + out-of-scope. **CRITICAL: before listing access/credentials as
   dependencies, ask whether you already have them.** If access already exists, frame it as "Client must
   maintain/preserve..." (do not revoke/restrict without coordination), NOT "Client must provide...". Typical
   categories: preservation of existing accesses, provision of new accesses, stakeholder access, environment
   stability, timely reviews.
6. **Assumptions** - separate from dependencies. Frame as "This SOW assumes that...". If false, may trigger a change
   request.

Summarize full scope outline (sections + H2 items) → confirm → proceed.

### Phase 3: Outcomes and delivery

1. **Outcomes** - for each scope deliverable, draft the business outcome. Scope = technical "what we build", outcome
   = business "what the client gains" (faster decisions, reduced costs, visibility, competitive advantage, etc.).
2. **Delivery** - phases? **ALWAYS ASK for the expected timeline** (do not invent). Hard deadlines? Phase
   dependencies? Keep the timeline section to a single paragraph with total duration - no week-by-week breakdown
   (over-commits and rots fast). Include a mandatory **Change Requests** paragraph.
3. **Appendices** - optional (architecture analysis, technology comparison, detailed requirements).

After Phase 3, generate the full markdown.

## Document structure

See `assets/SOW_STRUCTURE.md` for the canonical section structure, frontmatter schema, and per-section writing rules.
Do not improvise structure - follow the reference.

## Output

Save the markdown to the client's `docs/sow/` folder if a client folder exists; otherwise to the workspace. Filename:
`sow-{project-name-kebab-case}.md`.

Tell the user:
- where the file was saved
- that they can review and edit the markdown directly
- that running `/common:branding-docx` next produces the branded `.docx`

## Integration

- **Effort estimation** - if the user needs a detailed estimate, suggest the relevant estimator first; its output
  can inform Delivery and Outcomes.
- **`/common:branding-docx`** - runs next, converts this skill's markdown into the branded deliverable.
- **`/business:brief`** - the Business Brief is the analytical groundwork that precedes/refines this SOW; if the
  engagement is still in discovery, run `/business:brief` first.
