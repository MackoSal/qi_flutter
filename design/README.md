# Design System Workspace

This folder is the repository-owned bridge between the design tool (Penpot or
Figma), Flutter design tokens, and a future Widgetbook component catalog.

**Status:** no design has been created yet. The folders below are placeholders
that define where design artifacts go once the design work starts.

## Surfaces

- `tokens/` - exported or hand-curated design token JSON
  ([W3C Design Tokens format](https://tr.designtokens.org/format/)).
- `assets/` - exported design assets that are safe to commit (logos, icons).
- `docs/` - design decisions, mapping notes, and agent handoff docs.
- `penpot/` - Penpot self-hosting and MCP integration notes.
- `figma/` - Figma integration notes.

## Tooling Choice: Penpot vs Figma

This template supports both **Penpot** and **Figma**. Choose one based on the
project's needs, or mix them.

- **Penpot**: An open-source, self-hostable design tool. See
  `penpot/README.md` for self-hosting instructions and MCP integration.
- **Figma**: The industry-standard cloud-based design tool. See
  `figma/README.md`.

Once you decide on a tool, you can delete the folder of the tool you are not
using.

## Source of Truth

When the design system is implemented, Flutter tokens and shared widgets are
authoritative. The planned locations are:

- `app/flutter/lib/core/theme/` - theme and design tokens.
- `app/flutter/lib/core/widgets/` - reusable design-system widgets.

The design tool should mirror those tokens instead of inventing parallel names.
If a new value is needed, add it to the Flutter tokens first, then update the
design tool and `tokens/`.

See `docs/agent-workflow.md` for the step-by-step workflow.
