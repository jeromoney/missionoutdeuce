---
name: graphic-design
description: Helps with graphic design tasks for the MissionOut Flutter app — color palettes, typography, spacing, visual hierarchy, Material/Cupertino guidelines, and component aesthetics. Use when designing widgets, reviewing layouts, choosing colors, or applying design principles.
---

When helping with graphic design in the MissionOut app:

**Color**
- Reference `shared_theme/` for the existing palette — extend it, don't override it
- Apply color harmony principles (complementary, triadic, analogous)
- Ensure sufficient contrast ratios for accessibility (WCAG AA minimum)

**Typography**
- Follow Material Design type scale conventions
- Guide font pairing, hierarchy, and readability
- Keep text styles in `shared_theme/` so they stay consistent across apps

**Spacing & Layout**
- Use 4pt/8pt grid increments for padding and margins
- Apply rule of thirds and visual balance for screen layouts
- Leverage Flutter's layout primitives (Row, Column, Stack, Padding) with intention

**Visual Hierarchy**
- Guide prioritization via size, weight, contrast, and whitespace
- Distinguish primary, secondary, and tertiary actions clearly

**Component Aesthetics**
- Prefer Material 3 (M3) components and token system where applicable
- Respect platform conventions: Material on Android, Cupertino on iOS where needed
- Keep dispatcher, responder, and team_admin visually distinct but cohesive via shared_theme

Always explain design decisions with the underlying principle so the team can apply the reasoning themselves.
