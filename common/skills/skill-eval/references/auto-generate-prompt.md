# Auto-Generate Dataset Prompt

Template for generating a test dataset when the user hasn't provided one.
Use a fast, inexpensive model for generation — the task is well-defined.

## Prompt structure

Use an assistant-message prefill of ` ```json ` and a stop sequence of
` ``` ` so the response is raw parseable JSON. This is the standard
structured-data prompting pattern.

## The prompt

Fill the `{...}` placeholders in the template below:

```
You are generating a test dataset for evaluating a target prompt or skill.

## Target under test

<target>
{target_text}
</target>

## Dataset requirements

- Generate {count} test cases (default 8).
- Return a JSON array of case objects — nothing else.
- Cover three categories, with roughly these proportions:
  - Happy-path (~50%) — realistic, straightforward requests.
  - Edge cases (~30%) — unusual inputs, missing fields, ambiguous phrasing,
    boundary conditions, weird formatting.
  - Adversarial (~20%) — requests designed to stress the target
    (contradictory constraints, prompt-injection attempts, requests that
    tempt the target off-task).

## Required fields per case

{
  "case_id": "case_1",
  "task": "The user-facing request. Realistic, specific, detailed.",
  "expected_format": "json | code | regex | markdown | plain_text | html",
  "extra_criteria": "Any extra requirements that aren't covered by the task text.",
  "tags": ["happy-path" | "edge-case" | "adversarial", "optional-topic-tag"]
}

## Optional fields

- `must_contain` — list of substrings the output should contain.
- `must_not_contain` — list of substrings that indicate a regression.
- `inputs` — dict of values to fill named placeholders in the target, if
  the target uses them.

## Quality bar

- Tasks must be concrete. "Summarize this article" is bad; "Summarize this
  2-paragraph article into one bullet for a team chat thread" is good.
- Tasks should match the level of detail a real user would provide — which
  is inconsistent. Mix terse requests with rich, context-heavy ones.
- Every case should actually be solvable by the target as written. Don't
  generate tasks that require information the target doesn't have.
- Adversarial cases should be realistic stressors, not gibberish. Think
  "user who is confused and contradicts themselves", not "user who types
  random characters".

Return the JSON array now.
```

## Parsing the response

With the `json` prefill and ` ``` ` stop sequence, the response should parse
directly as a JSON array. Wrap it in the full dataset shape described in
`dataset-schema.md` before saving:

```python
import json
from datetime import datetime, timezone

parsed_cases = json.loads(response_text)
dataset = {
    "dataset_name": "auto-generated",
    "generated": True,
    "generator_model": "<model id used to generate>",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "cases": parsed_cases,
}
```

Save to `<workspace>/dataset.json`.

## Showing the user before running

After generation, show the user the list of `task` fields (maybe with tags)
and ask: "Here are the test cases I generated — want to tweak any before I
run the eval?" Don't start the run until they've had a chance to review.
Generated datasets are often 80% right and 20% off — that 20% is where the
user's edits earn their keep.
