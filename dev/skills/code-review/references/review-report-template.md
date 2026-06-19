# Review report template

Write to `docs/reviews/YYYY-MM-DD-review.md` (append `-2`, `-3` for repeat runs the same day). This location is
committable. Keep it factual — it mirrors what you present inline.

```markdown
# Code Review: <scope> — <YYYY-MM-DD>

**Scope:** <uncommitted | branch <base>...HEAD | path | all | PR/MR <id-or-url>>
**Reviewers run:** <list of dispatched dev: agents>
**Live testing:** <ran | skipped — reason>

## Summary

- Findings (raw): N → after de-dupe/triage: N
- Blockers: N | In-scope: N | Out-of-scope: N
- Fixed this pass: N | Deferred (follow-up): N
- Final verification: <PASS/FAIL — command + result>

---

## Group 1: <root-cause title>

- **Sources:** <agents that raised it> + <live-testing if applicable>
- **Bucket:** Blocker | In-scope | Out-of-scope
- **Rationale:** <one line — required for In-scope deferral and Out-of-scope>
- **Findings:**
  1. **[SEVERITY]** `file:line` — <description> _(source: agent)_
  2. **[SEVERITY]** `file:line` — <description> _(source: agent)_
- **Fix:** <what was done, or "deferred to follow-up", or "not fixed — out of scope">
- **Status:** FIXED | DEFERRED | OUT-OF-SCOPE | OPEN (needs manual attention)

## Group 2: <root-cause title>
...

---

## Validation Log

| Check | Result | Notes |
| --- | --- | --- |
| tests | PASS/FAIL | |
| lint | PASS/FAIL | |
| type / contract check | PASS/FAIL | |
| build | PASS/FAIL | |
| live endpoints | PASS/SKIPPED | |
```

## Rules for the report

- Only record what actually happened. If verification wasn't run or a phase was skipped, say so — don't imply a green
  result you didn't observe.
- Every In-scope-deferred and Out-of-scope group carries a one-line rationale, so the signal survives for a future
  ticket.
- The report is a record, not a fix authorisation — fixes happen in Phase 5 with the user, not by writing them here.
