# Team mapping

This is a **placeholder template — fill it in with your own team.** The table maps each potential reviewer's display
name to their handle on your git host and their email, so `/dev:open-pr` can take a chosen reviewer (by name, handle, or
email) and request the right person on the PR/MR.

The mapping is part of this skill — edit the table to add or remove people. The rows below are **examples only**;
replace them with your real teammates. Do **not** commit anyone who isn't on your team.

| Display name     | Git-host handle    | Email                  |
| ---------------- | ------------------ | ---------------------- |
| «Display Name 1» | «git-host-handle-1» | «email-1»             |
| «Display Name 2» | «git-host-handle-2» | «email-2»             |
| «Display Name 3» | «git-host-handle-3» | «email-3»             |

Notes:

- **Git-host handle** is the username on whatever host you use — it's what gets requested as the reviewer on the PR/MR.
- **Email** is used only to resolve the optional issue-tracker reviewer/QA account at runtime (see below); the tracker
  account id is **not** stored here — `/dev:open-pr` resolves it by looking the person up in your issue tracker by email
  (the Atlassian MCP account-lookup call) only when the optional field is configured.
- If the table has only one row, that person is the default reviewer; still confirm with the user before proceeding when
  no `reviewer` arg was passed.
- Keep this list current — `/dev:open-pr` can only request reviewers it finds here (or that the user types in when
  prompted).

## Optional: issue-tracker reviewer/QA field (opt-in)

If your team records the reviewer/QA on the issue itself, set your tracker's field id here and `/dev:open-pr` step 6
will populate it for the same person it requests on the PR/MR. **Leave it unset to skip that step entirely** — nothing
is hardcoded and the reviewer is still requested on the PR/MR.

```text
reviewer-qa-field-id: «your-tracker-field-id»   # e.g. a Jira user-picker custom field; leave unset to skip
```

When set, the field is treated as a user-picker whose value shape is `{ "accountId": "<resolved id>" }`.
