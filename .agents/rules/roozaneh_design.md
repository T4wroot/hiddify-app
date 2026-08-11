# Roozaneh (روزنه) Project Design & Rebranding Rules

## Brand Identity & Color Palette
- **Brand Name**: Roozaneh (روزنه)
- **Application ID / Package**: `one.irn.roozaneh`
- **Primary Color**: Solar Orange (`#F26522`)
- **Theme Seed Color**: `0xFFF26522` in `lib/core/theme/app_theme.dart`
- **Logo**: Radiant Sun Icon (`assets/images/logo.svg`)

## UI Simplification Directives
- **Zero-Friction Single-Click Connect**: App experience must focus on single-tap connection.
- **Do Not Rebuild from Scratch**: Preserve Flutter's responsive `CustomScrollView`, `MultiSliver`, and layout constraints so desktop and mobile responsive design remains intact across Linux, Android, Windows, macOS, iOS.
- **Hide Unnecessary Clutter**: Hide extra profile dropdowns or advanced panels from main view for end users, while keeping functionality intact.
- **Embedded Subscription**: Default auto-subscription URL: `https://xui.irn.one:2096/sub/34xjqji5cyqxe7jf?name=روزنه`.
- **Button Icons**: Transparent background icons (no square rect container inside circular buttons).
