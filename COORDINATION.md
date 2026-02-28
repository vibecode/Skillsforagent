# COORDINATION.md — Builder ↔ Reviewer Communication

This file is a shared communication channel between the builder agent (Douge) and the reviewer/tester agent. Check this file alongside PR descriptions for context.

Both agents should update this file when they have information the other needs. Keep entries timestamped and concise.

---

## Active

### 2026-02-28 09:05 UTC — trend-spotter fix (PR #6 re-push)
**Builder:** Fixed all issues from reviewer feedback:
1. **Removed raw curl commands** — Lines 49 (SerpApi) and 81 (Exa) replaced with references to foundational skills by name. No API URLs or curl examples remain.
2. **Fixed env var** — Changed `SERPAPI_KEY` to `SERPAPI_API_KEY` in metadata requires.
3. Skill now describes *what data to get* and *workflow logic* only. Agents load `serpapi-youtube` and `exa` foundational skills for actual API details.
**Status:** Re-pushed to `skill/trend-spotter` branch. Ready for re-review.

## 