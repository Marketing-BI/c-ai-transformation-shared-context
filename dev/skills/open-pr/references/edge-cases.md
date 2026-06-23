# Edge cases

Full failure-mode table for `/dev:open-pr`. "PR/MR" is whatever your git host calls it (pull request / merge request).

| Case                                                                       | Behaviour                                                                                                     |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| No accessible Atlassian site / wrong active site for your Jira ticket      | Switch with `atlassian_set_active_site` (step 0); halt if no accessible site matches. PR/MR is not created.    |
| Current git-host user can't be resolved (host not authenticated)           | Halt at step 0. Tell the user to authenticate their git host's CLI/MCP first.                                 |
| Jira key resolved but `jira_get_issue` returns 404 / not found             | Prompt to confirm/replace the key. Halt if the user can't supply a valid one. PR/MR is not created.          |
| Team mapping is empty (or becomes empty after self-filter)                 | Halt: "No eligible reviewer — add a teammate to the team mapping table, or invite one to the project."       |
| `reviewer` arg matches none (post self-filter)                             | List filtered mapping entries via `AskUserQuestion`; suggest editing the table.                              |
| `reviewer` arg resolves to the current git-host user                       | Tell the user "can't review your own PR/MR" and re-prompt from the filtered mapping.                         |
| `reviewer` arg matches multiple                                            | Prompt to disambiguate.                                                                                       |
| Branch has no upstream and `git push -u` fails                             | Halt before opening the PR/MR. Surface the error.                                                            |
| PR/MR creation fails on the host                                           | Halt.                                                                                                         |
| Open PR/MR already exists for the branch                                   | Offer "update reviewer only" or "cancel".                                                                     |
| User cancels at the confirmation gate                                      | Exit cleanly. No PR/MR opened.                                                                                |
