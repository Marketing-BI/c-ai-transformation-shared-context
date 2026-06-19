---
name: sales-coach
description: >
  Pre-call brief, personalized pre-call video script, OR post-call coaching for discovery and sales conversations.
  Built on a tactical discovery script - a multi-constraint diagnostic, workflow identification, demo close - layered
  over an open-ended discovery philosophy. Targets common rep weaknesses: qualification gaps (budget / revenue /
  team-size / decision-authority), shallow "why now", small-talk crowding, answering own questions, deflecting
  pitches, not quantifying pain in money. Three modes: PRE (pre-call brief), VIDEO (personalized pre-call video
  script), POST (call debrief + scorecard + follow-up email drafts). Triggers: "sales coach", "prep me for X call",
  "prep the X discovery call", "video for X", "pre-call video for X", "debrief the X call", "coach me on the call with
  X", "score my last call", "pre-call brief for X", "připrav mě na hovor s X", "připrav discovery hovor", "video pro
  X", "rozbor hovoru s X", "okomentuj můj hovor s X", "ohodnoť můj poslední hovor", "/business:sales-coach".
---

# Sales Coach

Pre-call brief, personalized pre-call video script, OR post-call coaching for discovery / sales conversations.

> **Trigger**: `/business:sales-coach` (or natural language: "prep me for the X call", "video for X", "debrief the X
> call")
>
> **Modes**:
> - **`pre`** - research + ICP fit + brief. Default when an upcoming call is referenced.
> - **`video`** - personalized pre-call video script (a short async screen-recording). Use when the rep wants the
>   pre-call video nudge prepped.
> - **`post`** - debrief + scorecard + two-email drafts + recommendation. Default when a recent transcript is
>   referenced.
>
> If ambiguous, ask once.

---

## How this skill thinks about a sales call

A discovery call usually arrives through one of two routes, and they call for two different lenses:

- **Inbound (paid-ad / self-booked) leads.** These follow the tactical **discovery script**
  (`references/call-script.md`) - tightly structured, rapid-fire qualification, fixed-length slot, demo-the-next-day
  close. The prospect knows it is a sales call and expects qualification.
- **Warm intros / outbound referrals.** These follow the softer **open-ended discovery philosophy**
  (`references/discovery-methodology.md`) - same goals (qualification, "why now", cost of inaction) but more
  conversational, no rapid-fire grilling.

Both routes share the **multi-constraint diagnostic** (`references/constraints.md`), the **decision rule** (can't
explain the business in 30s -> book a 2nd discovery), and the **tracked weaknesses** below.

When in doubt, lean on the script for inbound and open-ended discovery for warm intros. Mixed inbound (e.g., a senior
buyer who self-booked at a referred company) -> script structure with open-ended phrasing.

---

## Tracked weaknesses (score every post-call against these)

1. **Qualification gaps** - exiting discovery without budget / team size / revenue / decision-making authority
2. **Surface "why now"** - not probing deep enough (at least 2 layers)
3. **Small-talk crowding** - rapport eating into discovery time
4. **Answering own questions** - leaving no space for the prospect
5. **Deflecting prospect questions** - evading instead of answering directly and bridging back to discovery
6. **Not quantifying pain in money** - leaving cost-of-inaction abstract instead of forcing a number
7. **Leaving price gravity unclosed** - ending without anchoring an investment range

## Decision rule

**If the rep can't explain a prospect's business in 30 seconds post-call -> book a SECOND discovery call rather than
advancing to a sales / decision-maker-introduction call.**

## ICPs

Score each call against the team's own Ideal Customer Profile(s) - the segments, size bands, revenue bands, and
business models the offer is built for. Keep these in the team's ICP notes (e.g. a project context file or a saved
ICP-profiles file) and pull them in here; if the team runs more than one offer/ICP, score the prospect against each
and recommend which to lead with. For building or refreshing an ICP from market research, use `/business:prospector`.

## Proof points (deploy deliberately, don't broadcast)

Keep a short bank of the team's strongest case studies, each tagged with the kind of play it proves (e.g. "data
monetization", "embedded analytics", "back-office automation", "predictive maintenance"). Default: **hold proof
points back** unless the prospect explicitly asks for an example, then deploy the one that matches their situation.

## Rapport hook

Use a genuine personal commonality only when there is a real connection. Never force one.

## References (load only the ones you need)

- `references/call-script.md` - full tactical discovery call script. Load in PRE to anchor flow + anticipate; load in
  POST to score whether the script was followed.
- `references/constraints.md` - constraint library (how it shows up / how to say it back / how we solve it). Load to
  anticipate PRE and label what was heard POST.
- `references/video-nudge.md` - pre-call video script template + personalization protocol. Load in VIDEO mode.
- `references/discovery-methodology.md` - open-ended discovery philosophy + question-phrasing library. Load for
  warm-intro calls or for softer question phrasing on inbound.

---

## Mode A: PRE-CALL

### Step 1 - Identify the call

Ask which call, or pull from the calendar (next sales-related event in the next 24h). Capture: prospect name,
company, role, scheduled time + timezone, meeting link, call duration, inbound channel (paid ad / referral /
outbound).

### Step 2 - Research (in parallel)

- **CRM** - prospect + company; deal record, prior touchpoints, notes (via `/business:crm-ops` or the team's CRM
  interface)
- **Transcription tool** - any prior calls with this prospect or company
- **Web** - company website, recent press, the contact's professional profile (page fetch + web search)
- **Email** - prior threads with this prospect
- **Internal notes** - the team wiki / shared drive
- **Verify the booking-form data against reality** - employee count, role, and company name are frequently
  self-reported and wrong. The form is a hypothesis, not a fact.

### Step 3 - ICP fit score

Score against the team's ICP(s). If the team runs more than one offer, score each:

| Dimension | ICP fit | Notes |
|-----------|---------|-------|
| Employee count (verified) | check / ? / x | `<number, source>` |
| Revenue band | check / ? / x | `<if known>` |
| Industry / business model | ... | ... |
| Maturity signal (data / ops / AI) | ... | ... |

Recommend: **lead with `<offer A>`** / **lead with `<offer B>`** / **defer until discovery clarifies**. Justify in 1
line.

### Step 4 - Anticipate constraints

Based on industry / size / signals, predict which 2 of the **constraints** (see `references/constraints.md`) are most
likely to surface. This sharpens which probing questions to lean on during discovery.

### Step 5 - Pre-call video status

Check whether a pre-call video nudge has been drafted for this prospect. If missing and the call is >12h out, add a
TODO in the brief: "Pre-call video not yet sent - invoke `/business:sales-coach video` to draft it."

### Step 6 - Build the pre-call brief

Output a single copy-paste-ready markdown artifact:

```markdown
# Pre-call brief - <Prospect> @ <Company> - YYYY-MM-DD HH:MM TZ

## Snapshot
- Role, company, employee count (verified), revenue (if known)
- Industry, business model
- Recent signals / news
- Inbound channel: paid ad / referral / outbound
- Pre-call video: sent / not sent
- ICP fit: lead with <offer> because ...

## Rapport hooks
- Genuine commonalities (don't force one unless there's a real connection)

## Likely constraints (anticipate; refine live)
1. **Constraint #X** - why you'd expect to hear it; the "how it shows up" cues to listen for
2. **Constraint #Y** - same

## Discovery flow (anchor to references/call-script.md)
- Intro & frame (<=4 min): rapport -> name/role -> time frame -> "really understand / get clear / walk you through if
  it's a fit"
- Discovery: high-level story (<=2 min) + rapid-fire metrics (people, turnover, profit margin, growth YoY, revenue
  goal)
- Probing toward anticipated constraints (use 2-3 of the script's probing prompts; don't fire all of them)
- Desired state (12-month + future-state question)
- Pain & constraints (what have you tried; why hasn't it worked)
- Urgency (cost-of-inaction in money or specific consequences)
- Diagnosis -> 2 main constraints stated back -> workflow identification -> close

## Watch-outs (tracked weaknesses)
- [ ] Capture budget / team size / revenue / decision authority before exiting discovery
- [ ] Push past surface "why now" - at least 2 layers
- [ ] Cap small-talk at 3-5 minutes (tighter on short slots)
- [ ] Don't answer your own questions - count to 3
- [ ] Don't deflect - answer their questions directly, then bridge back
- [ ] Force a money / time / error number on cost of inaction
- [ ] Anchor an investment range before the call ends

## Proof-point cheat sheet
- Match a case study to the prospect's situation; otherwise hold back

## Decision rule reminder
If you can't explain their business in 30 seconds -> book a SECOND discovery, do NOT push a decision-maker intro.

## Advance-readiness checklist (advance only if all checked)
- [ ] Budget captured (directional is fine)
- [ ] Team size verified beyond the form
- [ ] Revenue band captured (rough order of magnitude)
- [ ] Decision authority confirmed
- [ ] "Why now" understood beyond surface
- [ ] ICP fit confirmed (or honest "no fit")
- [ ] Concrete next step agreed (demo / 2nd discovery / proposal)

## Specific to this call
<call-duration notes, language/cultural notes, time-pressure pacing, likely-real-reason-for-booking hypotheses to
validate live>
```

Save to `projects/sales/<prospect-slug>/pre-call-YYYY-MM-DD.md` (or the team's equivalent). Create the prospect folder
if it doesn't exist.

---

## Mode B: VIDEO

A personalized 60-90 second pre-call video script (a short async screen-recording sent the day before). The
template is fixed (`references/video-nudge.md`) - your job is to populate the per-prospect facts so the rep can read
it into the camera.

### Step 1 - Identify the call

Same as PRE Step 1.

### Step 2 - Light research (don't over-build)

- The prospect's **professional profile** - last 6-12 months: posts, role moves, company moves, content they've
  engaged with. Find 1 specific anchor.
- The prospect's **company website** - solution / capabilities page, customer logos, recent news / rebrand / award.
  Find 1 specific anchor.
- Anything to **congratulate** them on (rebrand, milestone, award, growth signal)? If not, drop that line.

You're not building a brief - just harvesting 2-3 specifics to make the script feel personal, not templated.

### Step 3 - Personalize the template

Use `references/video-nudge.md`. Populate:

- **First name**
- **Profile anchor** - name the specific post / topic / milestone, not "your background"
- **Website anchor** - name the specific page / logo / capability
- **Congratulations anchor** (optional)
- **Day of week** for the call ("tomorrow", "Tuesday", "Thursday")

**Anchor verification (critical):** only assert an anchor (a specific post, milestone, page, logo) if you actually
loaded and verified it this run. Any anchor you could not directly verify must be tagged `[VERIFY before recording]`
in the script - never put an invented "your post on X" into the rep's mouth on camera. If no anchor can be verified,
drop that line rather than fake it (same rule as the Congratulations anchor).

### Step 4 - Save the script

Save to `daily/video-nudges/YYYY-MM-DD-<prospect>.md` (or the team's equivalent). Format:

```markdown
# Pre-call video - <Prospect> @ <Company> - call YYYY-MM-DD HH:MM

## Script (read into camera)
> [full personalized script with anchors slotted in]

## Notes for recording
- Tone: warm, specific, low-pressure
- Length: ~60-90 sec
- Switch to website tab at: "Also, I wanted you to know I've been through your website..."
- Send via: video share link replied to the existing email thread

## Research used
- Profile anchor: <...>
- Website anchor: <...>
- Congratulations anchor: <... or "skipped - no anchor">
```

### Step 5 - Surface a reminder

Append a "Pre-call video - record & send" item to today's daily log under "Morning actions" so it surfaces in the
rep's start-of-day routine.

---

## Mode C: POST-CALL

### Step 1 - Pull the call

Get the transcript from the team's transcription tool. Search by prospect name + date if not provided directly; use a
transcript id if you have one.

### Step 2 - Extract the facts

- Who attended (their side and ours)
- What the rep said about the offer (which offer led; appropriate?)
- What the prospect revealed: business model, team, revenue, urgency, decision authority
- Decisions made on the call
- Action items (theirs and ours)

### Step 3 - Score against tracked weaknesses (always)

| Weakness | Score (check/partial/x) | Evidence (quote / timestamp) |
|----------|-------------------------|-------------------------------|
| Captured budget? | | |
| Captured team size? | | |
| Captured revenue? | | |
| Captured decision authority? | | |
| "Why now" depth (1-5) | | |
| Small-talk ratio (estimate %) - mark N/A on short/async transcripts | | |
| Answered own questions? | | |
| Deflected prospect questions? | | |
| Pitched / dropped a proof point unprompted? (should hold them back) | | |
| Named the constraint(s) back to the prospect? | | |
| Quantified pain in money / hours / errors? | | |
| Anchored an investment range? | | |

### Step 4 - Score against script checkpoints (only for paid-ad / inbound)

Skip if the call was a warm intro / referral. Otherwise:

| Checkpoint | Score | Evidence |
|------------|-------|----------|
| Intro frame stated (time frame + "really understand / get clear / walk you through if a fit") | | |
| Rapid-fire metrics captured (people, turnover, profit margin, growth, revenue goal) | | |
| 2 constraints named back from the constraint library | | |
| Magic-wand growth question asked | | |
| Workflow narrowed (constraint -> function -> workflow -> systems -> cost -> success number) | | |
| Success number captured (the number they'd call a win) | | |
| Demo call locked live on the call (calendar invite created) | | |
| Stakeholder pre-handle done (asked who else should see the demo) | | |

### Step 5 - 30-second business explanation test

Ask the rep to explain the prospect's business in 30 seconds. If they can't:

> **Recommendation: book a SECOND discovery, do NOT advance to the decision-maker call.**

### Step 6 - Coaching feedback (terse)

- **Wins** - what went well, named
- **Misses** - what to fix, with the specific transcript quote / timestamp
- **Next-call drill** - ONE specific behavior to practice. Don't dilute with three.

### Step 7 - Two follow-up email variants

**Variant A - warm/specific** (longer, references something they said):

```
Subject: ...
Hi <name>,
...
```

**Variant B - short/direct** (<= 100 words):

```
Subject: ...
Hi <name>,
...
```

Both ready to copy-paste. Match the language of the channel: write prospect-facing emails in the prospect's language;
write internal team notes in the team's working language.

### Step 8 - Recommendation

Pick one:

- **Advance to the decision-maker intro** - only if all advance-readiness boxes checked
- **Book a second discovery** - gaps remain; can't explain business in 30s; missing budget / authority / "why now"
- **Disqualify / archive** - not a fit; lost interest; bad-faith inquiry

### Step 9 - Update prospect record

In the prospect's record (`projects/sales/<prospect-slug>/` or the CRM via `/business:crm-ops`):

- Append the call to the timeline
- Update qualification status (budget / team / revenue / authority captured?)
- Update next action + date

### Step 10 - Long-game capture

Save coaching feedback to `knowledge/learning/sales-coach-YYYY-MM-DD-<prospect>.md` (or the team's equivalent) so
patterns surface over weeks. After every 5 sessions, suggest a meta-review: "Here's what's repeating across calls -
let's turn this into a saved learning."

---

## Rules across all modes

- **Be honest, not flattering.** The rep asked for coaching, not validation.
- **Specific transcript quotes / timestamps** when calling out a miss. Vague feedback wastes the loop.
- **Don't put words in anyone's mouth** - distinguish "the open-ended approach would frame this as..." from an actual
  quote.
- **Copy-paste-ready output** - no "you could draft something like..." placeholders.
- **Two email variants by default** in POST mode unless the rep specifies otherwise.
- **Language matching**: external prospect comms in the prospect's language; internal team notes in the team's working
  language.
- **Verify ICP numbers before stating them as fact** - the booking form is self-reported; pull from the CRM / web
  before treating it as truth.
- **Reference the right framework**: paid-ad / inbound = the script. Warm intro = open-ended discovery. Mixed = script
  structure + open-ended phrasing. Always name which lens you're using in the brief.

## Integration

- **`/business:prospector`** - to build or refresh the ICP this skill scores against.
- **`/business:crm-ops`** - to read and update the prospect/deal record cleanly.
