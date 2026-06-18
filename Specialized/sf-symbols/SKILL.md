---
name: sf-symbols
display_name: SF Symbols
description: >
  SF Symbols guidance for Apple-platform interfaces. Use when:
  (1) choosing systemImage names for iOS actions, status, navigation, tab bars,
  dashboards, or controls, (2) selecting monochrome, hierarchical, palette,
  multicolor, variable-value, or animated symbol rendering, (3) matching symbol
  weight, scale, and accessibility to nearby SwiftUI text, (4) using
  symbolEffect for meaningful feedback, (5) checking SF Symbols API signatures,
  UIKit equivalents, and platform availability.
metadata: {"openclaw": {"emoji": "🔣"}}
---

<!-- Source: CharlesWiltgen/Axiom axiom-codex/skills/axiom-design/skills/sf-symbols.md and sf-symbols-ref.md. License: MIT. Marketplace frontmatter adjusted; upstream guidance preserved in references. -->

# SF Symbols

Use this skill when choosing, styling, or animating SF Symbols in native Apple
interfaces. Symbols should communicate an action or state, not decorate the UI.

Read `references/sf-symbols.md` for symbol selection, rendering mode decisions,
variable-value symbols, animation discipline, accessibility, and custom symbol
workflow.

Read `references/sf-symbols-ref.md` when you need exact SwiftUI, UIKit, or
AppKit API signatures, symbolEffect options, platform availability, variable
value behavior, or rendering mode syntax.

Core rules:

- Prefer `Label("Title", systemImage: "...")` when text and icon travel
  together.
- Use icon-only buttons only for familiar actions and always include an
  accessibility label.
- Match symbol size and weight to adjacent text with `.font(...)`, then adjust
  with `.imageScale(...)` only when needed.
- Choose rendering mode by meaning: monochrome for quiet utility,
  hierarchical for depth, palette for layered status, multicolor when Apple's
  built-in colors carry the meaning.
- Use `.symbolEffect` as feedback for a state change or live activity, not as
  decoration.
