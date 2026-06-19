# Grader Rubric — 1 to 10

The grader scores each output against the task on a 1–10 integer scale.
Anchoring matters: if the grader defaults to the middle, the eval is useless.
The rubric below defines what each band actually means.

## The scale

### 10 — Exemplary

The output is exactly what a senior practitioner would write. It fully
solves the task, handles edge cases, is clear, well-formatted, and has
nothing extraneous. No realistic revision would improve it.

### 9 — Near-perfect

Solves the task completely with only cosmetic issues (minor phrasing, a bit
long-winded, a format choice you'd tweak). A reviewer would approve it
as-is.

### 8 — Strong

Correct and complete in substance, but has one noticeable issue — maybe an
edge case it didn't address, a slightly off tone, or a minor factual
imprecision. Still ship-worthy after a quick pass.

### 7 — Good

The output does the job. Some real weaknesses (missing one of several
requested items, weak on the edge cases, some filler), but a user would
accept it. This is the realistic modal score for "fine" outputs.

### 6 — Partially useful

Gets the main idea but has substantive gaps: missed requirements, wrong
assumptions, or notable inaccuracies. Needs real revision before use.

### 5 — Mediocre

About half of what was asked. The output is on-topic but either
incomplete, unfocused, or has several issues piling up. A reviewer would
send it back.

### 4 — Weak

Addresses the task superficially. Major requirements missed, wrong
emphasis, or confidently incorrect claims. Not useful as drafted.

### 3 — Poor

Barely addresses the task. Most requirements missed or answered wrong.
Would take more work to fix than to redo.

### 2 — Bad

Off-topic, doesn't engage with the actual request, or gets most things
wrong. The output creates more work for the reader than it saves.

### 1 — Broken

Empty output, refusal on a reasonable task, garbled text, unparseable
format when format was required, or actively harmful / misleading content.

## Calibration anchors

To keep scores stable across runs, anchor against these reference points:

- **"Generate a valid JSON config"** where the output is syntactically
  valid JSON with all requested keys but one extra explanation line at the
  top → **5 or 6**. Don't give 8 for "almost there but not usable".
- **"Write a three-paragraph summary"** where the output is four paragraphs
  but all on point → **8**. The format miss is minor.
- **"Explain concept X"** where the explanation is factually correct but
  only covers half the concept → **5**.
- Output doesn't parse when `expected_format` was set → **cap at 4**, no
  matter how impressive the prose.

## When to use the syntax-check backstop

If `expected_format` is machine-checkable (`json`, `code`, `regex`),
verify it parses before finalizing the score. A confident-sounding code
snippet with a syntax error is a 3, not a 7. The hard cap at 4 for unparseable
output exists specifically to neutralize this failure mode.

## What NOT to reward

- Length for its own sake. A 300-word answer to a "one-sentence" task isn't
  thorough, it's undisciplined.
- Confident tone. "Here's the definitive answer:" doesn't change whether
  the answer is correct.
- Matching the grader's own style preferences. Judge against the task, not
  your taste.

## What NOT to penalize

- Formatting the user didn't specify. If they asked for "a summary" and got
  bullets, that's fine — deduct only if bullets are clearly wrong for the
  context.
- Not echoing the question back. Brevity is a feature, not a gap.
- Stylistic choices within the acceptable range. Two different good answers
  can both score 9.
