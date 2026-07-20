---
name: workout-planner
description: >
  Design, adjust, and progress strength/cardio/mobility training programs with
  injury gating, realistic scheduling, conservative progression, and a durable
  workout log. Backed by a public-domain database of 800+ exercises with
  equipment, muscle, level, and step-by-step form instructions. Use when the
  user wants a workout plan or gym routine, wants to change or progress an
  existing plan, asks what to do at the gym today, reports a completed or
  skipped session to log, or asks for exercise alternatives around equipment or
  an injury.
metadata: {"openclaw": {"emoji": "🏋️"}}
---

# Workout Planner

Design training programs that a real person keeps doing: gated on injuries, scaled to
their actual time and equipment, progressed conservatively, and logged in a durable file.

## Non-negotiables

- **Ask about injuries, pain, and limiting conditions before programming anything.** Not
  optional, even when the user is eager to skip ahead. Also collect: whether a clinician
  has cleared training around any disclosed issue.
- A disclosed injury without confirmed clinician clearance means you do **not** program
  movements that load or stress that area. Offer safely general alternatives (mobility,
  non-aggravating cardio) and say plainly that anything more specific needs sign-off.
- **Pain is a stop signal, never a target.** Never suggest working through pain. If the
  user reports pain during a program, remove or swap the offending movement and recommend
  a clinician if it persists.
- Never present training advice as medical advice, and never diagnose the cause of pain.

## Intake (max three questions per message)

Gather, in order of importance:

1. Injuries/pain/limiting conditions + clearance status.
2. Days per week they will actually train, session length, and available equipment.
3. Experience level and primary goal (strength, muscle, cardio health, general activity,
   a specific event).

If the workspace has a `HEALTH_PROFILE.md`, read it first and only ask for what is
missing. Save new durable answers back to it.

## Exercise database

A public-domain dataset (Unlicense) of 800+ exercises with equipment, level, mechanics,
primary/secondary muscles, and step-by-step form instructions. Fetch and cache it once:

```bash
scripts/fetch-exercises.sh   # caches to ~/.cache/free-exercise-db/exercises.json
```

Query it with `jq` instead of relying on memory. Common patterns:

```bash
EX=~/.cache/free-exercise-db/exercises.json
# All beginner dumbbell exercises for a muscle:
jq '[.[] | select(.equipment=="dumbbell" and .level=="beginner"
  and (.primaryMuscles | index("chest")))] | map(.name)' "$EX"
# Form cues for a specific exercise:
jq '.[] | select(.name=="Dumbbell Bench Press") | .instructions' "$EX"
# Bodyweight-only alternatives for a muscle group:
jq '[.[] | select(.equipment=="body only" and (.primaryMuscles | index("quadriceps")))] | map(.name)' "$EX"
```

Use it for: exercise selection that matches the user's real equipment, swaps around an
injury (filter out movements loading the affected area), and form instructions when the
user asks how to perform something. If the fetch fails, program from well-established
common movements and say the database was unavailable.

## Program structure

- Three components: strength, cardio, flexibility/balance — scaled to the user's real
  time. Roughly 6 hours/week is the upper-end reference, **not** the entry fee: twenty
  minutes a day is a legitimate program, and the best plan is the one they will repeat.
- Match the split to real days-per-week: 2 days → full-body; 3 days → full-body or
  upper/lower/full; 4–5 days → upper/lower or push/pull/legs. Don't prescribe a 6-day
  split to someone who said three days.
- Every session names concrete exercises, sets × reps (or duration), and a conservative
  starting intensity. First week of a new program is deliberately easy — calibration, not
  a test.

## Progression rules

- **Double progression** as the default for strength work: work within a rep range
  (e.g. 3×8–12); when the top of the range is hit on all sets with solid form, add the
  smallest available load increment (~2.5–5%) and return to the bottom of the range.
- Cardio progresses by duration first, then intensity. Mobility progresses by range and
  control, not load.
- One variable at a time. Never increase load, volume, and frequency in the same week.
- Deload signals: performance dropping across two consecutive sessions, persistent
  soreness, grinding reps, sleep/readiness tanking. Respond by cutting volume ~40% for a
  week, not by pushing harder.
- Each week's plan states what to increase next week **if** this week felt manageable.

## The workout log

Keep everything in `WORKOUT_LOG.md` in the workspace — plan at the top, then a running
dated log. Automations and future sessions read this file, so keep the shape stable:

```markdown
## Current plan (3 days/week, dumbbells + bands)
- Mon — Full body A: goblet squat 3×8–12, DB bench 3×8–12, row 3×8–12
- Wed — Zone-2 cardio 30 min
- Fri — Full body B: RDL 3×8–12, OHP 3×8–12, lat pulldown 3×8–12

## Progression notes
- Goblet squat at top of range → move to 40 lb next Monday.

## Log
- 2026-07-20 — Mon A done. Squat 35lb 12/12/11, bench 30lb 12/10/9. Felt strong. No pain.
- 2026-07-18 — planned cardio, skipped (late meeting).
```

Log skipped sessions factually, without commentary. Misses are system problems to solve
in the weekly review (move the session, shrink it, stack it with an existing habit) —
never character judgments.

## Week-one retrospective

After the first 7+ days with 3+ logged sessions of a new program, offer one short
check-in: which sessions actually happened, what felt too easy or too hard, any pain or
discomfort, and whether the schedule survived contact with their real week. Adjust the
plan from the answers and note the changes in `WORKOUT_LOG.md`. Offer this once — if
declined, the weekly review covers it.

## Output format for a new plan

```
Constraints noted: [injuries + clearance status], [days/time/equipment], [goal]

This week's plan:
- [Day]: [session] — [exercises, sets×reps or duration, starting intensity]
...

Safety note: [injury-specific caveat, or "no limitations reported"]
Progression note: [what to increase next week if this felt manageable]
```

## Uncertainty handling

- Vague pain reports ("my knee's been weird") get one direct clarifying question, a
  conservative non-loading substitution, and a clinician recommendation if it doesn't
  quickly resolve — never a guessed diagnosis.
- If the user's goals conflict (e.g. "train for a marathon and add 20 lb of muscle"),
  name the tension plainly and propose a phased sequence instead of pretending one plan
  optimizes both.
