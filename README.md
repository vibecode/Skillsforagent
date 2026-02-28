# Skills for Agents

Skills repository for OpenClaw agents. Contains foundational and specialized skills that agents can import and use.

## Structure

```
├── Foundational/     — Base skills that document APIs, services, and tools. Other skills reference these.
├── Specialized/      — Niche skills that build on foundational skills for specific workflows.
├── COORDINATION.md   — Communication channel between builder and reviewer agents.
└── Plan.MD           — Progress tracker for skill development.
```

## How This Repo Works

Two agents collaborate through this repo:

### Builder Agent (Douge)
- Researches API docs thoroughly, builds foundational and specialized skills
- Pushes skills to feature branches (`skill/<name>`)
- Creates PRs with test instructions
- Labels PRs `needs-testing` when ready for review
- Reads reviewer feedback and fixes issues on failed tests

### Reviewer/Tester Agent
- Watches for PRs labeled `needs-testing`
- Pulls the branch and imports the skill into a **clean session** (no prior context of the skill)
- Tests the skill by attempting to use it naturally based on its description triggers
- Comments on the PR with results:
  - **Pass:** What was tested, what worked, evidence (command outputs, screenshots)
  - **Fail:** What broke, exact error, what was confusing, suggested fixes
- Labels PR `tested-pass` or `tested-fail`
- Checks `COORDINATION.md` for additional context or instructions from the builder

### Human (Kyle)
- Drops skill requests to the builder agent
- Reviews and merges PRs that pass testing
- Final authority on all merges

## PR Workflow

```
Builder creates branch → pushes skill → opens PR (needs-testing)
    ↓
Reviewer pulls branch → tests in clean session → comments results
    ↓
Pass → label: tested-pass → Kyle reviews & merges
Fail → label: tested-fail → Builder reads feedback → fixes → re-pushes → cycle repeats
```

## Reviewing a Skill — Guidelines for the Tester Agent

When you pick up a PR labeled `needs-testing`:

1. **Read the PR description** for test instructions and what the skill does
2. **Check `COORDINATION.md`** for any additional context from the builder
3. **Import the skill** into your environment
4. **Open a new, clean session** — do NOT test in the same session where you imported it
5. **Try to trigger the skill naturally** — use the kinds of prompts a real user would. The skill's description tells you what should trigger it.
6. **For API skills:** Actually call the endpoints if you have the API key. Verify the request format, headers, and response parsing are correct.
7. **For setup skills:** Run the setup script. Verify it installs what it claims.
8. **Report on the PR:**
   - What you tested (specific prompts/commands)
   - What worked
   - What failed (with exact errors)
   - Whether the skill instructions were clear or confusing
   - Any missing information you had to guess at
9. **Also update `COORDINATION.md`** with your test results summary

## Skill Quality Standards

Every skill in this repo must:
- Have proper YAML frontmatter (name, description with trigger scenarios, metadata)
- Folder name matches the `name` field
- Description includes specific numbered trigger scenarios
- Body is under 500 lines
- Examples use real, working endpoints
- References are linked from the body with guidance on when to read them
- No extraneous files (README, CHANGELOG inside skill folders)

## Labels

| Label | Meaning |
|-------|---------|
| `needs-testing` | Builder finished, ready for reviewer |
| `tested-pass` | Reviewer verified it works |
| `tested-fail` | Reviewer found issues (see PR comments) |
| `foundational` | Base API/service skill |
| `specialized` | Builds on foundational skills |
