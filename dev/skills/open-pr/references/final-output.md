# Final output

Printed by step 7 once the PR/MR is open. Base case — two lines:

```text
PR/MR: <pr_mr_url>
Jira:  <site>/browse/<TICKET>
```

When the **optional** issue-tracker reviewer/QA field was configured and set in step 6, add a third line noting who it
was set to:

```text
PR/MR: <pr_mr_url>
Jira:  <site>/browse/<TICKET> — reviewer/QA set to <displayName>
```

`<site>` is the `url` from the resource resolved in step 0. Omit the "reviewer/QA set to" note when no tracker field is
configured — in that case the reviewer is requested on the PR/MR only.
