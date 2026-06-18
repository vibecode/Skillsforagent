---
name: liquid-glass
display_name: Liquid Glass
description: >
  Real iOS 26 Liquid Glass implementation guidance. Use when:
  (1) building SwiftUI controls with glassEffect, Glass, GlassEffectContainer,
  or glass button styles, (2) replacing fake blur or material cards with the
  real Apple glass APIs, (3) choosing Regular versus Clear glass, (4) auditing
  Liquid Glass legibility, tinting, nesting, accessibility, or scroll-edge
  behavior, (5) planning app-wide Liquid Glass adoption without breaking
  standard system components.
metadata: {"openclaw": {"emoji": "🫧"}}
---

<!-- Source: CharlesWiltgen/Axiom axiom-codex/skills/axiom-design/skills/liquid-glass.md and liquid-glass-ref.md. License: MIT. Marketplace frontmatter adjusted; upstream guidance preserved in references. -->

# Liquid Glass

Use this skill for real iOS 26 Liquid Glass work. Do not fake glass with blur,
opaque cards, or hand-rolled translucency when the platform API is available.

Read `references/liquid-glass.md` before writing or reviewing custom glass
effects. It covers the actual SwiftUI API shape, variant discipline, tinting,
legibility, accessibility, performance, and review criteria.

Read `references/liquid-glass-ref.md` when planning broader adoption across
navigation, controls, menus, sheets, app icons, platform variants, or backwards
compatibility.

Core rules:

- Prefer standard SwiftUI/UIKit controls first; many adopt Liquid Glass when
  rebuilt with the iOS 26 SDK.
- For custom glass, use `.glassEffect()`, `Glass`, `GlassEffectContainer`,
  `.buttonStyle(.glass)`, or `.buttonStyle(.glassProminent)`.
- Use Regular glass by default. Use Clear only for media-heavy content with a
  deliberate dimming and legibility plan.
- Keep content and navigation layers distinct. Glass belongs on functional
  controls and navigation, not decorative content cards.
- Gate iOS 26-only API with `#available` and provide a pre-iOS fallback.
- Test with light and dark mode, Reduce Transparency, Increase Contrast,
  Reduce Motion, Dynamic Type, and scrolling content behind the glass.
