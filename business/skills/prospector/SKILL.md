---
name: prospector
description: >
  Customer-intelligence / ICP research for a product, service line, or offer. Discovers where a target audience
  actually talks online, extracts their exact pain language, scores severity (frequency x emotional intensity),
  separates buyers-ready from venters, and synthesizes an Ideal Customer Profile plus an engagement strategy. Use for
  positioning, messaging refresh, campaign targeting, new-segment exploration, or sharpening an existing ICP - in any
  language. If the request names a specific call, prospect, or meeting, defer to `/business:sales-coach`, NOT this
  skill. Triggers (only when NO specific named call/person is mentioned): "ICP research", "research the ICP for X",
  "who buys X and why", "audience research for X", "pain-point research", "buyer persona for X", "where do my buyers
  hang out", "messaging research", "výzkum ICP", "průzkum cílové skupiny", "kdo kupuje X a proč", "výzkum bolestí
  zákazníků", "persona kupujícího", "výzkum pro messaging", "/business:prospector".
---

# Customer-Intelligence / ICP Research

Turn messy real-world discussion into a defensible Ideal Customer Profile and an engagement plan. This is the
**market/positioning** layer. For a single upcoming call, use `/business:sales-coach pre` instead.

> **Trigger**: `/business:prospector` (or "research the ICP for X", "who buys X and why", "messaging research for X")
>
> **Modes**:
> - **`full`** (default) - complete report: pain points -> buyer language -> ready-to-buy signals -> ICP ->
>   engagement strategy -> communities.
> - **`refresh`** - lighter pass aimed at copy/messaging: pain clusters + exact buyer language + ready-to-buy signals
>   only. Use when refreshing a landing page, ad, or email sequence.

---

## Hard rules (apply always, regardless of mode or whether research runs)

- **Never fabricate quotes or evidence.** Every quote must trace to a real source. Label inference vs. direct
  evidence explicitly. This binds even if the user says "skip the research" or "just give me quotes" - refuse to emit
  invented quotes as real; offer sourced research or clearly-labeled `[ILLUSTRATIVE - not a real customer]` examples
  instead.
- **Gate on a vague offer.** If any of {entity, what-it-does, problem} is missing, ask 2-3 clarifying questions in a
  single message before researching. Do not proceed on a fuzzy offer.
- **State the breadth actually reached.** If access limits research below the target, say so; never pad to hit a
  count.

## Step 0 - Inputs (ask, one at a time, only if missing)

1. **Which entity / offer?** A product, a service line, or a specific offer. Pull defaults from any existing ICP notes
   the team keeps (e.g. a project context file or a saved ICP-profiles file) before asking.
2. **What it does** (1-2 sentences) and **what problem it solves** (1-2 sentences).
3. **Mode** (`full` / `refresh`) and any known segment to focus on.

If the offer is vague, ask 2-3 clarifying questions before researching. Do not proceed on a fuzzy offer.

## Step 1 - Check what we already know

Read any existing ICP-profiles note and relevant prior sales/market notes first. Build on existing ICP work; do not
restart from zero. Note what is already established vs. what this run should validate or extend.

## Step 2 - Research (fan-out)

Search where buyers actually discuss the problem. Prioritize the **last 6 months**; label older material as
older-but-relevant.

- Platforms: Reddit, Quora, LinkedIn posts/comments, YouTube comments, G2, Trustpilot, Capterra, Stack Exchange,
  niche forums, app reviews.
- Query patterns: `"[problem] frustrating / annoying / sucks"`, `"why is [process] so hard"`, `"alternatives to
  [competitor]"`, `"I wish there was [outcome]"`, `"[competitor] problems"`, `"how to [outcome] without [pain]"`.
- Use web search + page fetch. For dense single sources, escalate to a browser-driving tool (navigate -> read page
  text) if one is wired up.
- **Never fabricate quotes.** Every quote must trace to a real source. Label inference vs. direct evidence
  explicitly.
- Aim for breadth (target 50+ relevant discussions); if access limits you, state the actual breadth reached.

## Step 3 - Analyze (internal)

Cluster complaints -> rank by frequency x emotional intensity -> flag "hair-on-fire" segments most ready to buy.
Capture repeated exact phrases. Map objections and failed workarounds. (Do not show this scratch work; produce the
report.)

## Step 4 - Output (Markdown)

Save to `knowledge/work/icp-{entity-or-offer-kebab}-{YYYY-MM-DD}.md` (or the team's equivalent work folder). Sections:

**`full`:**

1. **Pain-Point Analysis** - 5-7 pains, each: description, severity 1-10, 2-3 exact quotes (with source), frequency,
   emotional triggers.
2. **Buyer Language Patterns** - 10+ phrases, each: phrase -> what it really means.
3. **Ready-to-Buy Signals** - explicit solution requests, urgency indicators, price expectations mentioned, current
   workarounds + why they fail.
4. **Ideal Customer Profile** - who they are, context/environment, psychographics, behaviors, jobs-to-be-done, buying
   triggers, key objections. Map back to the offer's fit.
5. **Engagement Strategy** - top 3 communities to enter, how to enter each credibly, resonant content angles,
   landmines to avoid.
6. **Top Communities** - up to 20: platform, name, size, activity, link, why valuable, top 3 complaints.
7. **Executive Summary** - where buyers are, what they say, top pains + severity, hair-on-fire segments, the language
   to mirror, best channels/angles.

**`refresh`:** sections 1, 2, 3 only - optimized for immediate copy.

## Step 5 - Offer to persist

Ask whether to fold validated findings into the team's ICP-profiles note (append, do not overwrite) so future calls
and campaigns inherit them.

## Tone

Analytical, evidence-driven, no hype. This is strategic research, not ad copy.

## Integration

- **`/business:sales-coach`** - for a single named call or prospect (pre-call brief, pre-call video, post-call
  coaching). If the request names a specific person/meeting, hand off there.
- **`/business:brief`** - this skill's ICP and pain findings can inform the business context of an engagement brief.
