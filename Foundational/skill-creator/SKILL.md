---
name: skill-creator
display_name: Skill Creator
description: >
  Create new skills, modify and improve existing skills, and measure skill
  performance for the Chorus agent platform. Use this skill whenever a user wants
  to create a skill from scratch, edit or optimize an existing skill, run evals to
  test a skill, benchmark skill performance with variance analysis, or optimize a
  skill's description for better triggering accuracy. Also use when turning a
  conversation workflow into a reusable skill, or when the user says "make this a
  skill" or "let's build a skill for X". This is the go-to skill for any skill
  development, testing, or improvement work on the Chorus platform.
metadata: {"openclaw": {"emoji": "🛠️"}}
---

# Skill Creator

A skill for creating new skills and iteratively improving them on the Chorus agent platform.

At a high level, the process of creating a skill goes like this:

- Decide what the skill should do and roughly how it should do it
- Write a draft of the skill
- Create a few test prompts and run them via `claude -p` or sub-agent sessions
- Help the user evaluate the results both qualitatively and quantitatively
  - While runs happen in the background, draft some quantitative evals if there aren't any. Then explain them to the user.
  - Use the `eval-viewer/generate_review.py` script to show the user the results, and also let them look at the quantitative metrics
- Rewrite the skill based on feedback from the user's evaluation
- Repeat until satisfied
- Expand the test set and try again at larger scale

Your job is to figure out where the user is in this process and help them progress. Maybe they want to make a skill from scratch — help narrow down intent, write a draft, write test cases, run them, iterate. Or maybe they already have a draft — go straight to eval/iterate.

Be flexible. If the user says "I don't need evaluations, just vibe with me", do that instead.

After the skill is done, you can also run the skill description optimizer to improve triggering accuracy.

## Communicating with the user

Pay attention to context cues about the user's technical level. In the default case:

- "evaluation" and "benchmark" are borderline, but OK
- For "JSON" and "assertion", see cues from the user before using without explanation

It's OK to briefly explain terms if in doubt.

---

## Creating a skill

### Capture Intent

Start by understanding the user's intent. The current conversation might already contain a workflow to capture (e.g., "turn this into a skill"). If so, extract answers from the conversation history first — tools used, sequence of steps, corrections the user made, input/output formats observed. The user may need to fill gaps and should confirm before proceeding.

1. What should this skill enable the agent to do?
2. When should this skill trigger? (what user phrases/contexts)
3. What's the expected output format?
4. Should we set up test cases? Skills with objectively verifiable outputs benefit from test cases. Skills with subjective outputs (writing style) often don't. Suggest the appropriate default, but let the user decide.

### Interview and Research

Proactively ask about edge cases, input/output formats, example files, success criteria, and dependencies. Wait to write test prompts until this is ironed out.

If useful for research (searching docs, finding similar skills), research via sub-agents if available, otherwise inline.

### Write the SKILL.md

Based on the interview, fill in:

- **name**: Skill identifier (kebab-case, max 64 chars)
- **description**: When to trigger, what it does. This is the primary triggering mechanism — include both what the skill does AND specific contexts for when to use it. All "when to use" info goes here, not in the body. Make descriptions a bit "pushy" to combat under-triggering. Max 1024 characters.
- **metadata**: OpenClaw-specific metadata (emoji, required env vars, etc.)
- **the rest of the skill**

### Skill Writing Guide

#### Anatomy of a Skill

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description required)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/    - Executable code for deterministic/repetitive tasks
    ├── references/ - Docs loaded into context as needed
    └── assets/     - Files used in output (templates, icons, fonts)
```

#### Progressive Disclosure

Skills use a three-level loading system:
1. **Metadata** (name + description) — Always in context (~100 words)
2. **SKILL.md body** — In context whenever skill triggers (<500 lines ideal)
3. **Bundled resources** — As needed (unlimited, scripts can execute without loading)

**Key patterns:**
- Keep SKILL.md under 500 lines; add hierarchy with clear pointers if approaching the limit
- Reference files clearly from SKILL.md with guidance on when to read them
- For large reference files (>300 lines), include a table of contents

**Domain organization**: When a skill supports multiple domains/frameworks, organize by variant:
```
cloud-deploy/
├── SKILL.md (workflow + selection)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```
The agent reads only the relevant reference file.

#### Principle of Lack of Surprise

Skills must not contain malware, exploit code, or any content that could compromise system security. A skill's contents should not surprise the user in their intent. Don't create misleading skills or skills designed to facilitate unauthorized access or data exfiltration.

#### Writing Patterns

Prefer the imperative form in instructions.

**Defining output formats:**
```markdown
## Report structure
ALWAYS use this exact template:
# [Title]
## Executive summary
## Key findings
## Recommendations
```

**Examples pattern:**
```markdown
## Commit message format
**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

### Writing Style

Explain to the model **why** things are important rather than using heavy-handed MUSTs. Use theory of mind and make the skill general, not super-narrow to specific examples. Write a draft, then look at it with fresh eyes and improve it.

### Test Cases

After writing the skill draft, come up with 2-3 realistic test prompts — the kind of thing a real user would actually say. Share them with the user: "Here are a few test cases I'd like to try. Do these look right, or do you want to add more?" Then run them.

Save test cases to `evals/evals.json`:

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

See `references/schemas.md` for the full schema (including the `assertions` field, added later).

## Running and evaluating test cases

This section is one continuous sequence — don't stop partway through.

Put results in `<skill-name>-workspace/` as a sibling to the skill directory. Within the workspace, organize by iteration (`iteration-1/`, `iteration-2/`, etc.) and within that, each test case gets a directory (`eval-0/`, `eval-1/`, etc.). Create directories as you go.

### Step 1: Spawn all runs (with-skill AND baseline) in the same turn

For each test case, launch two runs — one with the skill, one without. Use `claude -p` for individual runs or `sessions_spawn` for parallel sub-agent sessions. Launch everything at once so it all finishes around the same time.

**With-skill run** (using `claude -p`):

```bash
claude -p "Read the skill at <path-to-skill>/SKILL.md and follow its instructions to complete this task: <eval prompt>. Save outputs to <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/"
```

Or via `sessions_spawn`:

```
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/

Before starting, read the skill at <path-to-skill>/SKILL.md and follow its instructions.
```

**Baseline run** (same prompt, no skill reference):
- **Creating a new skill**: No skill at all. Same prompt, save to `without_skill/outputs/`.
- **Improving an existing skill**: The old version. Snapshot it first (`cp -r <skill-path> <workspace>/skill-snapshot/`), then point the baseline at the snapshot. Save to `old_skill/outputs/`.

Write an `eval_metadata.json` for each test case. Give each eval a descriptive name based on what it's testing.

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

### Step 2: While runs are in progress, draft assertions

Use wait time productively. Draft quantitative assertions for each test case and explain them to the user. Good assertions are objectively verifiable and have descriptive names.

Update the `eval_metadata.json` files and `evals/evals.json` with assertions once drafted.

### Step 3: As runs complete, capture timing data

When each sub-agent completes, you may receive timing info. Save to `timing.json` in the run directory:

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3
}
```

### Step 4: Grade, aggregate, and launch the viewer

Once all runs are done:

1. **Grade each run** — spawn a grader sub-agent that reads `agents/grader.md` and evaluates each assertion against the outputs. Save results to `grading.json`. The grading.json expectations array must use the fields `text`, `passed`, and `evidence`.

2. **Aggregate into benchmark** — run the aggregation script:
   ```bash
   python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
   ```
   This produces `benchmark.json` and `benchmark.md`. Put each with_skill version before its baseline counterpart.

3. **Do an analyst pass** — read `agents/analyzer.md` for what to look for: non-discriminating assertions, high-variance evals, and time/token tradeoffs.

4. **Launch the viewer**:
   ```bash
   python <skill-creator-path>/eval-viewer/generate_review.py \
     <workspace>/iteration-N \
     --skill-name "my-skill" \
     --benchmark <workspace>/iteration-N/benchmark.json \
     --static <output_path>
   ```
   For iteration 2+, also pass `--previous-workspace <workspace>/iteration-<N-1>`.

   Use `--static <output_path>` to write a standalone HTML file. To share it with the user, write it to the Public directory (e.g., `~/.openclaw/workspace/Public/eval-review.html`) and send them the URL. Feedback will be downloaded as `feedback.json` when the user clicks "Submit All Reviews".

5. **Tell the user**: "I've generated the results viewer. There are two tabs — 'Outputs' lets you click through each test case and leave feedback, 'Benchmark' shows the quantitative comparison."

### Step 5: Read the feedback

When the user tells you they're done, read `feedback.json`:

```json
{
  "reviews": [
    {"run_id": "eval-0-with_skill", "feedback": "the chart is missing axis labels", "timestamp": "..."},
    {"run_id": "eval-1-with_skill", "feedback": "", "timestamp": "..."}
  ],
  "status": "complete"
}
```

Empty feedback means the user thought it was fine. Focus improvements on test cases with specific complaints.

---

## Improving the skill

### How to think about improvements

1. **Generalize from the feedback.** Skills will be used millions of times across many prompts. Rather than fiddly overfitting changes or oppressive MUSTs, use different metaphors or recommend different patterns. It's cheap to try.

2. **Keep the prompt lean.** Remove things that aren't pulling their weight. Read the transcripts — if the skill wastes time on unproductive steps, remove those parts.

3. **Explain the why.** Explain the reasoning behind every instruction. LLMs are smart and respond better to understanding than to rigid structures. If you find yourself writing ALWAYS or NEVER in all caps, reframe with reasoning instead.

4. **Look for repeated work.** If all test runs independently wrote similar helper scripts, bundle that script in `scripts/` and tell the skill to use it.

Take your time on improvements. Write a draft revision, look at it fresh, and improve it. Get into the head of the user and understand what they want.

### The iteration loop

After improving:

1. Apply improvements to the skill
2. Rerun all test cases into `iteration-<N+1>/`, including baselines
3. Launch the reviewer with `--previous-workspace` pointing at the previous iteration
4. Wait for user review
5. Read feedback, improve again, repeat

Keep going until:
- The user says they're happy
- Feedback is all empty
- You're not making meaningful progress

---

## Advanced: Blind comparison

For rigorous comparison between two skill versions, read `agents/comparator.md` and `agents/analyzer.md`. Give two outputs to an independent sub-agent without telling it which is which, and let it judge quality.

This is optional and most users won't need it. The human review loop is usually sufficient.

---

## Description Optimization

The description field is the primary mechanism that determines whether an agent invokes a skill. After creating or improving a skill, offer to optimize the description.

### Step 1: Generate trigger eval queries

Create 20 eval queries — a mix of should-trigger and should-not-trigger. Save as JSON:

```json
[
  {"query": "the user prompt", "should_trigger": true},
  {"query": "another prompt", "should_trigger": false}
]
```

Queries must be realistic. Include personal context, file paths, column names, company names, URLs. Mix lengths, focus on edge cases.

For **should-trigger** queries (8-10): Different phrasings, cases where users don't name the skill but clearly need it, uncommon use cases.

For **should-not-trigger** queries (8-10): Near-misses — queries sharing keywords but needing something different. Don't make them obviously irrelevant.

### Step 2: Review with user

Present the eval set using the HTML template:

1. Read `assets/eval_review.html`
2. Replace placeholders:
   - `__EVAL_DATA_PLACEHOLDER__` → JSON array of eval items
   - `__SKILL_NAME_PLACEHOLDER__` → skill name
   - `__SKILL_DESCRIPTION_PLACEHOLDER__` → current description
3. Write to the Public directory (e.g., `~/.openclaw/workspace/Public/eval-review.html`) and send the user the URL
4. User can edit, toggle, add/remove entries, then click "Export Eval Set"

### Step 3: Run the optimization loop

Tell the user: "This will take some time — I'll run the optimization loop in the background and check on it periodically."

Save the eval set to the workspace, then run in the background:

```bash
python -m scripts.run_loop \
  --eval-set <path-to-trigger-eval.json> \
  --skill-path <path-to-skill> \
  --model <model-id-powering-this-session> \
  --max-iterations 5 \
  --verbose
```

Use the model ID from your system prompt (the one powering the current session) so the triggering test matches what the user actually experiences.

While it runs, periodically tail the output to give the user updates on which iteration it's on and what the scores look like.

This handles the full optimization loop automatically. It splits the eval set into 60% train and 40% held-out test, evaluates the current description (running each query 3 times to get a reliable trigger rate), then calls `claude -p` to propose improvements based on what failed. It re-evaluates each new description on both train and test, iterating up to 5 times. When it's done, it produces an HTML report showing the results per iteration and returns JSON with `best_description` — selected by test score rather than train score to avoid overfitting.

### How skill triggering works

Understanding the triggering mechanism helps design better eval queries. Skills appear in the agent's `available_skills` list with their name + description, and the agent decides whether to consult a skill based on that description. The important thing to know is that agents only consult skills for tasks they can't easily handle on their own — simple, one-step queries like "read this PDF" may not trigger a skill even if the description matches perfectly. Complex, multi-step, or specialized queries reliably trigger skills when the description matches.

This means your eval queries should be substantive enough that an agent would actually benefit from consulting a skill. Simple queries like "read file X" are poor test cases — they won't trigger skills regardless of description quality.

### Step 4: Apply the result

Update the skill's SKILL.md frontmatter with the best description. Show before/after and report scores.

---

## Validation

Before publishing, validate the skill:

```bash
python <skill-creator-path>/scripts/quick_validate.py <skill-path>
```

This checks:
- SKILL.md exists with valid YAML frontmatter
- Name is kebab-case, max 64 chars
- Description is under 1024 chars, no angle brackets
- Only allowed frontmatter properties

---

## Packaging

Package the skill for distribution:

```bash
python -m scripts.package_skill <path/to/skill-folder>
```

This creates a `.skill` file (zip format) excluding build artifacts.

---

## Reference files

The agents/ directory contains instructions for specialized sub-agents. Read them when spawning the relevant sub-agent:

- `agents/grader.md` — How to evaluate assertions against outputs
- `agents/comparator.md` — How to do blind A/B comparison
- `agents/analyzer.md` — How to analyze why one version beat another

The references/ directory:
- `references/schemas.md` — JSON structures for evals.json, grading.json, benchmark.json, etc.

---

## Core Loop Summary

1. Figure out what the skill is about
2. Draft or edit the skill
3. Run the skill on test prompts via `claude -p` or sub-agent sessions
4. Evaluate outputs with the user (viewer + quantitative evals)
5. Repeat until satisfied
6. Validate and package the final skill
