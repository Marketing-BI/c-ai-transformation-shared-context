# SOW Structure Reference

Canonical structure and per-section writing rules for a Statement of Work. Referenced from `SKILL.md`.

## Frontmatter

```yaml
---
project_name: "Project Name"
document_type: "Statement of Work"
client_name: "Firstname Lastname"
client_company: "Company Name"
supplier_name: "Firstname Lastname"
created_date: "YYYY-MM-DD"
revision_date: "YYYY-MM-DD"
valid_until: "YYYY-MM-DD"
---
```

`valid_until` defaults to `revision_date + 30 days` unless the user specifies otherwise.

## Section structure

All headings use hierarchical numbering (1., 1.1., 1.1.1.).

```
# Executive Summary
(1 page, business-level, no technical details, prose paragraphs)

# Scope
(intro paragraph summarizing overall scope)
## Deliverable 1 Name
(1–4 paragraphs per deliverable)
### Sub-deliverable if needed
(bold paragraph headers for smaller breakdowns within a deliverable)
## Deliverable 2 Name
...
## Documentation
## Knowledge Transfer

# Out of Scope
(intro paragraph)
## Item 1
(1–2 paragraphs explaining what is excluded and why)
## Client-Side Responsibilities
## Third-Party Software Support

# Dependencies
(intro paragraph + bullet list of general client responsibilities)
## Specific Dependency 1
(1 paragraph each)
## Specific Dependency 2
...

# Assumptions
(numbered or bulleted list of key assumptions)

# Outcomes
(intro paragraph connecting outcomes to business value)
## Outcome 1 - mirrors Scope deliverable 1
(1 paragraph, business-focused)
## Outcome 2 - mirrors Scope deliverable 2
...

# Delivery
(intro paragraph about delivery approach)
## Phase One - Phase Name
(2–3 paragraphs: what happens, why, output, caveats)
## Phase Two - Phase Name
...
## Timeline and Sequencing
(narrative description, not a Gantt chart)
## Change Requests
(standard paragraph about change request process)

# Appendix 1 - Title (optional)
...
```

## Section writing rules

### Executive Summary

- Max 1 page when rendered
- Business audience - no technical jargon
- Structure: context/problem → proposed solution → expected impact → the supplier's role
- Pure prose, no bullets
- Must make sense to a C-level reader who skips everything else

### Scope

- Always opens with an intro paragraph under the H1
- Each deliverable: H2 with 1–4 paragraphs describing WHAT will be delivered and WHY
- For complex deliverables, use **bold paragraph headers** (not H3) for sub-topics
- H3 reserved for genuine sub-deliverables - distinct work items

### Out of Scope

- Same format as Scope, focused on exclusions
- Each H2 explains what is excluded and briefly why
- ALWAYS cross-check against Scope for contradictions
- Bullets acceptable for listing specific excluded items within a sub-section

### Dependencies

- Opens with a brief intro paragraph and a bullet list of general client responsibilities
- Each H2 dependency: 1 paragraph explaining what is needed and why
- Imperative tone: "Client must provide...", "Client must ensure..."
- **CRITICAL**: if access already exists on the supplier side, frame as "Client must maintain/preserve..." not
  "Client must provide..."

### Assumptions

- Keep separate from Dependencies to avoid repetition
- Dependencies = what the client must actively do/provide
- Assumptions = conditions believed to be true that underpin the SOW
- If an assumption proves false, may trigger a change request

### Outcomes

- Each outcome mirrors a scope deliverable, from the business perspective
- Scope says "we will build X" → Outcome says "the client will gain Y"
- Focus on business value: revenue, efficiency, risk reduction, competitive advantage, adoption, time-to-value

### Delivery

- Narrative description of phases, not a project plan
- Each phase: what happens, key activities, expected outputs, disclaimers or risks
- Timeline and Sequencing: separate H2 - general duration estimates, sequencing logic, conditions for starting
- Change Requests paragraph is mandatory: work outside defined scope requires a written change request approved by
  both parties

## Em dashes

NEVER use em dashes (`—`) anywhere in the document. Use regular dashes with spaces (` - `), commas, parentheses, or
restructure the sentence.
