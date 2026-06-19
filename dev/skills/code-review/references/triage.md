# Review Triage gate

Reviewer output is **advisory input, never auto-applied.** Agents are biased toward reporting; the orchestrator's
job is to filter before any fix. This is the same triage discipline the plan-review gate uses.

## Classify every group

Put each grouped finding (Critical and Recommendation alike) into exactly one bucket:

- **Blocker** — a real bug, data/security risk, or a clear violation of a stated project rule, on a reachable code
  path. Must be fixed before the work is considered done. Live-testing 500s, stack-trace leaks, and auth bypasses are
  always Blockers.
- **In-scope** — a valid improvement that belongs to this change and is worth doing now or as an agreed follow-up.
  Decided with the user.
- **Out-of-scope** — a preference, a theoretical concern without evidence, a pre-existing issue the diff didn't
  touch, or a real-but-unrelated improvement. Documented with a one-line rationale; not fixed here.

## Filtering tests (apply to each group)

1. **Bug or preference?** Wrong results / data leak / rule violation = bug → Blocker or In-scope. Works correctly but
   "could be structured differently" = preference → Out-of-scope (unless it violates a project rule).
2. **Is the severity backed by evidence?** Check the agent's evidence for Critical/High findings — is the path
   actually reachable? Does the evidence support the level? Downgrade unsupported severity.
3. **Worth the churn now?** A fix touching many files to save little, or in code about to be rewritten → In-scope as
   a deferred follow-up, not a Blocker.
4. **Hidden duplicate?** Two descriptions of the same path → one group, keep the most actionable.

## Post-triage calibration

If post-triage counts exceed these, re-check — you're probably still keeping preferences as Blockers:

- Blockers (Critical): 0–2 · In-scope: a handful · Out-of-scope: whatever's left, documented.

Zero Blockers is a normal, good outcome. Record the full triage table (per group: sources, bucket, rationale) in the
report so the signal is preserved even for items deferred.
