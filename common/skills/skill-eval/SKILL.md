---
name: skill-eval
description: >
  Runs an objective evaluation pipeline over a target skill or raw prompt to
  measure its performance. Use whenever the user asks to "evaluate a prompt",
  "test a skill", "benchmark my prompt", "score my prompt", "run evals",
  "eval workflow", "test my skill", "how good is this prompt", "compare two
  prompts", "A/B test prompts", "grade prompt outputs", "vyhodnotit prompt",
  "otestuj prompt", "otestuj skill", "zhodnoť kvalitu promptu", "evaluace
  promptu", "spustit evaly", "porovnej dva prompty", or uploads an evals.json /
  dataset.json and asks for scoring. Also triggers when the user wants to
  iterate on a prompt but isn't sure whether a change made it better or worse.
  The skill auto-generates or loads a test dataset, runs the target against it,
  has an LLM judge grade every output on a 1–10 rubric, and delivers the results
  as a re-runnable HTML report. Trigger token: "/common:skill-eval".
---

# Skill & Prompt Eval

An end-to-end evaluation pipeline for prompts and skills. It takes a target
(either a raw prompt or a `SKILL.md` path), a test dataset (auto-generated or
user-supplied), runs every test case through the target, grades the outputs
with an LLM judge, and ships the results as a re-runnable HTML report the user
can re-open, tweak, and re-run.

The goal is to replace "I tested it a few times and it looks fine" with a
defensible, objective score that survives the next prompt tweak.

## When this skill runs

Trigger on any request that boils down to "how good is this prompt/skill,
measured objectively?" — including before/after comparisons when the user has
edited a prompt. If the user just wants content generated with an existing
skill, that's the job of that content skill, not this one.

## Core eval loop

This skill implements the six-step workflow:

1. **Capture the target** — the prompt or skill under test.
2. **Acquire a dataset** — either auto-generate test cases or load a file.
3. **Interpolate** each test case's input into the target to form a full
   prompt variation.
4. **Run** every variation to collect model outputs.
5. **Grade** each output with an LLM judge returning `strengths`, `weaknesses`,
   `reasoning`, and a numerical `score` (1–10).
6. **Report** — average the scores, render an HTML report, and return a
   concise summary plus next-step suggestions to the user.

Do not skip grading. A hardcoded "score = 10" defeats the entire purpose of
the pipeline.

## Step 1 — Capture the target

Figure out what's being evaluated. Ask only for what you can't infer:

- **Skill under test** — user passes a path like
  `~/.claude/skills/my-skill/SKILL.md` or refers to an installed skill by
  name (e.g. "test my `my-skill` skill"). Resolve installed names by
  searching the available-skills list for a matching location.
- **Raw prompt under test** — user pastes a prompt or points to a `.md`/`.txt`
  file containing one.
- **Two variants** — if the user wants an A/B comparison (e.g. "is v2 better
  than v1?"), capture both targets and run the full loop on each, then show
  both in the report.

Read the target into memory. Note any `{placeholder}` or `{{variable}}`
patterns — those are the slots test cases will fill.

If no placeholders exist, you'll interpolate each test case's `task` text by
appending it (see Step 3).

## Step 2 — Acquire the dataset

Two paths, both supported:

### Path A — Load from file

Check the usual locations in order:

1. Path the user handed you explicitly.
2. `evals/evals.json` next to the target skill.
3. A `dataset.json` / `evals.json` in the user's working folder.

The expected shape is documented in `references/dataset-schema.md`. Read it
before parsing — the grader needs `task` at minimum and optionally
`expected_format`, `must_contain`, `must_not_contain`, or `extra_criteria` to
feed into the judge.

### Path B — Auto-generate

When no dataset exists, or the user explicitly says "generate test cases",
use the template in `references/auto-generate-prompt.md` to produce one.
Typical parameters:

- **Count** — default 8 cases. Ask only if the user seems to want a specific
  number. More than 20 is rarely useful for iteration; fewer than 5 makes the
  average too noisy.
- **Coverage intent** — the generator prompt asks for a mix of happy-path,
  edge cases, and adversarial cases so the score reflects realistic stress.

Generation uses an assistant-message prefill of ` ```json ` and a stop
sequence of ` ``` ` so you get raw parseable JSON (the standard structured-data
pattern). Save the generated dataset to `<workspace>/dataset.json` and show the
user a quick preview — let them edit before you continue if they want to.

## Step 3 — Build prompt variations

For each test case, build the concrete prompt that will be executed:

- If the target has named placeholders, substitute from the test case's
  `inputs` dict.
- If the target has no placeholders, wrap the test case like:

  ```
  <target_prompt>
  {target text}
  </target_prompt>

  <task>
  {test_case.task}
  </task>
  ```

  XML tags matter — they keep the judge from confusing the target with the
  input.

Store each built variation alongside its test case ID so the report can show
both later.

## Step 4 — Run the target

Spawn the runner subagent (`agents/runner.md`) in parallel for every test
case — one subagent per case. Parallelism is the whole point; running
sequentially on a 20-case dataset is painfully slow.

Each runner subagent:

- Loads the target (skill body or prompt text).
- Executes the built variation.
- Captures the output as a single string.
- Returns a JSON blob with `{ case_id, output, stop_reason, duration_ms }`.

Aggregate all runner results before moving on. If a runner errors, mark that
case as failed but keep going — one broken case shouldn't kill the report.

## Step 5 — Grade outputs

Spawn the grader subagent (`agents/grader.md`) in parallel — one per
case. Pass it the original task, the model output, and any `extra_criteria`
from the test case.

The grader uses the rubric in `references/grader-rubric.md` and returns:

```json
{
  "case_id": "...",
  "score": 7,
  "strengths": ["..."],
  "weaknesses": ["..."],
  "reasoning": "..."
}
```

Insist on the structured JSON format. A score without reasoning is useless —
and asking for reasoning before the score is what stops the judge from
defaulting to "7 out of 10, seems fine I guess". See the grader prompt for
the assistant prefill + stop sequence that enforces this.

If the target has a known expected output (e.g. valid JSON, valid code),
supplement the model-based score with a lightweight syntax check and take
the mean — the rubric explains when to do this. It's a useful backstop even
though the primary grader is model-based.

## Step 6 — Build the HTML report

This is the deliverable. Render the HTML report from the template in
`assets/artifact-template.html` as the starting point.

The report shows, at minimum:

- **Headline score** — arithmetic mean across all test cases, big and obvious.
- **Score distribution** — a small histogram or bar chart so outliers are
  visible.
- **Per-case breakdown** — task, generated output, grader score, grader
  reasoning. Collapsible so the page stays scannable.
- **Target snapshot** — the exact prompt/skill text that was tested.
- **Metadata** — dataset source (generated vs. file), model used, timestamp,
  number of cases.

Populate the template's placeholders with your aggregated data (see the
template's `<script>` tag — data is injected as a JS variable, no server
calls required for the basic view).

### Re-run hook

If the host environment exposes a callback the report can invoke (for example,
a "send prompt" bridge), wire the "Re-run" button to re-invoke this skill with
the same dataset — this is the whole reason for using an interactive report
instead of a static one. Where no callback is available, the button falls back
to telling the user to ask in chat to "re-run the eval". Don't drop the re-run
affordance.

## Concurrency and cost

Cap parallel subagents at 8 by default. Users on shared API keys can hit
rate limits fast. If you catch a 429, back off and retry sequentially for
the remaining cases rather than failing the whole run.

Use a fast, inexpensive model (a small/fast model from your AI provider — the
1–10 rubric is well within a small model's capabilities) for both the target
run (when the user hasn't specified a model) and the grader. Offer a stronger
model as an override for higher-stakes evals.

## Iteration workflow

After the report lands, ask the user what they want to do next. The common
answers are:

- **Edit the prompt and re-run** — they tweak, you re-run with the *same*
  dataset, and the report shows the delta. This is the power move.
- **Expand the dataset** — add more cases, especially in areas where the
  score was weak. Keep the old cases so scores stay comparable.
- **Ship it** — score is high enough, save the dataset to
  `evals/evals.json` next to the skill so future runs are reproducible.

## Files in this skill

- `agents/runner.md` — instructions for the subagent that runs a single test
  case against the target.
- `agents/grader.md` — instructions for the subagent that scores one output.
- `references/dataset-schema.md` — JSON shape for `dataset.json` / `evals.json`.
- `references/grader-rubric.md` — the 1–10 scoring rubric the grader uses.
- `references/auto-generate-prompt.md` — prompt template for generating a
  dataset from scratch.
- `assets/artifact-template.html` — the HTML report skeleton.

These `agents/` and `references/` files are **internal resources** of this
skill, loaded by relative path — they are not separately dispatched plugin
agents, so no plugin-qualified `subagent_type` is needed.

## What this skill is not

- Not a replacement for human review on subjective content (creative writing,
  brand voice nuance). LLM judges correlate decently with human judgment but
  aren't ground truth. Use the score to filter regressions, not to decide if
  something is *great*.
- Not a production monitoring system. It's an offline iteration tool.
- Not a training loop. It doesn't update the prompt for you — it tells you
  whether your update was an improvement.
