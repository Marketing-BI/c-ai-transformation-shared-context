# Dataset Schema

The dataset is a JSON file with a list of test cases. The runner uses `task`
and the runner's interpolation logic; the grader uses everything.

## Minimal shape

```json
{
  "dataset_name": "my-skill-v1",
  "generated": false,
  "cases": [
    {
      "case_id": "case_1",
      "task": "The user-facing request the target will receive."
    }
  ]
}
```

That's the floor. Everything below is optional but improves grading fidelity.

## Full shape

```json
{
  "dataset_name": "my-skill-v1",
  "generated": true,
  "generator_model": "<model id used to generate>",
  "created_at": "2026-04-23T10:00:00Z",
  "cases": [
    {
      "case_id": "case_1",
      "task": "Write a regex that matches US phone numbers.",
      "inputs": {
        "variable_name": "value used to fill a named placeholder"
      },
      "expected_format": "regex",
      "must_contain": ["\\d"],
      "must_not_contain": ["TODO"],
      "extra_criteria": "Must handle optional country code and various separators.",
      "tags": ["regex", "happy-path"]
    }
  ]
}
```

### Field reference

- `case_id` — unique ID within the dataset. String. Used to correlate
  runner and grader outputs.
- `task` — the task the user is asking the target to solve. Always present.
- `inputs` — dict of `{placeholder_name: value}` used when the target has
  named placeholders like `{topic}` or `{{company}}`.
- `expected_format` — one of `json`, `code`, `regex`, `markdown`,
  `plain_text`, `html`. Enables the syntax-check backstop in the grader.
- `must_contain` — list of substrings the output must contain. The grader
  will dock points if any are missing.
- `must_not_contain` — list of substrings that, if present, indicate a
  regression (e.g. placeholder strings, forbidden words).
- `extra_criteria` — free-text extra requirements passed to the grader
  verbatim. Use this for things that don't fit the other fields.
- `tags` — optional labels for slicing results later (e.g. `happy-path`,
  `edge-case`, `adversarial`).

## Case categories to aim for

A balanced auto-generated dataset covers:

1. **Happy-path** (~50%) — the straightforward, representative requests.
2. **Edge cases** (~30%) — unusual inputs, missing fields, weird formatting.
3. **Adversarial** (~20%) — prompts designed to break the target
   (prompt injection attempts, ambiguous phrasing, contradictory
   constraints).

## Where the file lives

Preferred locations, checked in order:

1. Path the user explicitly handed to the skill.
2. `evals/evals.json` next to the target skill's `SKILL.md`.
3. `dataset.json` in the user's working folder.

Auto-generated datasets get saved to `<workspace>/dataset.json` so the user
can inspect/edit before the run starts.
