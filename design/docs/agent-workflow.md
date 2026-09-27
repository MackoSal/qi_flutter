# Agent Design-System Workflow

Use this workflow when changing visual language, design tokens, reusable UI
components, or Widgetbook stories.

If the theme, widget, or Widgetbook locations below do not exist yet, create
them in the listed places instead of inventing new ones.

1. Read Flutter tokens in `app/flutter/lib/core/theme/`.
2. Check existing reusable widgets in `app/flutter/lib/core/widgets/`.
3. Reuse existing tokens before adding new ones.
4. If the Penpot or Figma MCP server is available, inspect the matching design
   file and components.
5. Update Flutter tokens and widgets.
6. If Widgetbook is set up, add or update use cases in
   `app/flutter/lib/widgetbook/`.
7. Keep `design/tokens/` in sync with the Flutter tokens.
8. Run the standard checks from `app/flutter/`:

```bash
dart format --set-exit-if-changed lib/ test/
flutter analyze
flutter test
```

For behavior-bearing UI, also run the feature tests or golden tests that cover
the touched widgets.

Do not treat design-tool exports as authoritative when they conflict with
checked-in Flutter tokens. Resolve the conflict explicitly and update both
surfaces.
