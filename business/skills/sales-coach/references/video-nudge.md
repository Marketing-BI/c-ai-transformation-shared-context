# Reference: Pre-call video nudge - script

A 60-90 second personalized pre-call video (a Loom-style async screen-recording) sent the day before / morning of a
sales call. Purpose: signal preparation, build warmth, lower the prospect's no-show / mental-opt-out risk.

Used in: VIDEO mode of the sales-coach skill.

---

## Template (the rep reads this into the camera)

> Hey **[First name]**, I saw you booked in with me tomorrow.
>
> I just wanted to let you know I've had a look at your profile and what you've been up to recently. **[Profile anchor
> - a specific post, milestone, or topic they've engaged with]** was really helpful, thank you.
>
> *[Switch to their website tab]*
>
> Also, I wanted you to know I've been through your website. I read through your **[specific page - solution /
> capabilities / about / etc.]** and had a look at some of the logos you've got. **[Congratulations anchor - if
> there's something to congratulate them on, drop it here; otherwise skip this line]**
>
> Anyway, the reason I'm sending you this video is I just wanted you to know I've done my homework and I am showing up
> to our call prepared.
>
> If you have any questions specifically about our process or how this works, shoot me a reply to this email.
>
> Otherwise, I'm really excited to meet with you **[tomorrow / Tuesday / Thursday]**, talk soon.

---

## Personalization protocol - what to fill in

| Slot | Source | What good looks like |
|------|--------|----------------------|
| **First name** | Calendar / booking / email signature | Verified spelling, no "Hi there" |
| **Profile anchor** | Their professional profile, last 6-12 months of posts / role changes | Name a specific post topic, recent role move, content they wrote (e.g., "your post on [topic]", "your move to [role]"). Generic "your background" doesn't land. |
| **Specific website page** | Their company website (solution, capabilities, about, customers) | Name the actual page - "your solutions page", "your capabilities overview", "the case study on [client]" |
| **Congratulations anchor** | Recent news, rebrand, milestone, award, product launch, headcount growth | Name the specific thing. If there's no anchor, skip the entire "Congratulations" line - don't fake it. |
| **Day of week** | Tomorrow's day name | "tomorrow" if recording the day before; "Monday / Tuesday / ..." if recording further out |

---

## Tone & recording notes

- **Warm, specific, low-pressure.** Not pitchy.
- **60-90 seconds** - anything longer and the prospect won't finish it.
- **Switch tabs visibly** at the moment marked above (profile -> their website). Show prep, don't just claim it.
- **One take if possible.** Re-records sound robotic; mild imperfection signals authenticity.
- **Send via:** a video share link, replied directly to the existing booking-confirmation email thread. Subject
  prefix: "Re: [original subject]".

---

## What this skill produces in VIDEO mode

For each upcoming sales call within the next 24h, save a file to `daily/video-nudges/YYYY-MM-DD-<prospect>.md` (or the
team's equivalent) with:

1. **The personalized script** (template above with slots filled in)
2. **Notes for recording** (tone, length, tab switch, send-via)
3. **Research used** (profile anchor, website anchor, congratulations anchor) - so the rep can sanity-check the
   personalization
4. **A reminder** appended to the daily log under "Morning actions" so it surfaces in the start-of-day routine
