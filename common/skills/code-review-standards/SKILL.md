---
name: code-review-standards
description:
  Standards for reviewing a pull/merge request or preparing code for review — reviewer process, comment categories
  ([blocking] / [nit] / [question]), author responsibilities, scope discipline, and merge criteria. Load whenever the
  user is reviewing or about to review code, or getting code ready for review. Triggers on: "review this PR",
  "review this MR", "code review", "review my changes", "prepare for review", "request review", "zkontroluj PR",
  "zkontroluj MR", "code review", "revize kódu", "připrav kód k review", "projdi můj diff", "review mého kódu",
  "/common:code-review-standards". These are the review *standards* — not the QA orchestrator.
---

# Code Review Standards

Standards for reviewing a pull/merge request (PR/MR) or preparing code for review. Language-agnostic: the principles
below apply regardless of the implementation language or git host.

## Reviewer Process

1. **Read the PR/MR description first.** Understand the intent before looking at the diff.
2. **Read the tests first.** Tests describe expected behavior — they tell you what the code should do.
3. **Read the diff.** Evaluate whether the implementation achieves what the tests describe.
4. **Triage findings before leaving comments.** For each finding, filter:
   - Style preference not enforced by the linter/formatter? → Skip entirely
   - No clear, better alternative to propose? → Use `[question]` instead of requesting a change
   - Fix effort disproportionate to the benefit? → Downgrade to `[nit]`; do not block
   - Only a marginal performance gain or a highly improbable / theoretical security flaw? → Skip entirely
   - Related findings with a common root cause? → Bundle into one comment, state the probable cause
   - Real issue, but outside this change's scope? → Do not comment inline and do not file a ticket. Add to an
     **Out-of-scope observations** section at the end of the review for the human to decide whether to plan.
5. **Leave comments.** Categorize every comment as `[blocking]`, `[nit]`, or `[question]`.

## Comment Standards

- Reference line numbers and quote code when relevant
- Propose an alternative when requesting a change — don't just flag the problem
- One issue per comment — do not bundle multiple concerns
- `[blocking]` — must be resolved before merge
- `[nit]` — optional improvement; do not request changes for nits alone
- `[question]` — seeking understanding; may not require a change

## Author Responsibilities

Before requesting review:

- Self-review your own diff — fix obvious issues first
- Verify CI is green
- The PR/MR description explains the "why", not just the "what"
- Scope is contained — the change does one thing

When responding to review:

- Resolve all `[blocking]` comments or negotiate explicitly with the reviewer
- Acknowledge `[nit]` and `[question]` comments — even with "noted, won't change"
- Re-request review after addressing feedback — don't go silent

## Scope Discipline

- Reviewers must not request changes to code outside the diff under review
- Authors must not bundle unrelated changes to avoid review debt
- If review surfaces an important unrelated issue, surface it in **Out-of-scope observations** and let the human
  decide whether to plan it — do not file a ticket automatically and do not block the change on it

## Merge Criteria

A PR/MR is ready to merge when:

- All `[blocking]` comments resolved
- At least one approval from someone other than the author
- All CI checks pass
- No unresolved merge conflicts

## Turnaround Expectations

- Reviewer: first response within one business day of the review request
- Author: address feedback within one business day of review
- If a PR/MR sits with no response for two business days, the author should follow up
