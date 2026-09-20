# Gemini Project Instructions

Read and follow [AGENTS.md](AGENTS.md) before working in this repository. It is the source of truth for the architecture, migration goals, and platform constraints.

Task-specific workflows are available under `.gemini/skills/` and `.gemini/rules/`. Use a workflow only when it is relevant to the user's request. Treat tool names and commands in those files as optional: use them only when they are available in the active Gemini environment.

## AI Working Rules
- **Git Worktree:** Agents must ALWAYS work on an isolated `git worktree` when making significant changes to the project. Do not modify the main branch directly without a worktree.
- **Planning & Approvals:** Whenever you create implementation plans (`implementation_plan.md`), task lists, or any documents that require user review and approval during the planning phase, you MUST save them in the `tmp_ai_tools/` directory (not in the hidden artifact or system directories). This ensures they remain accessible to other AI tools in the repository.
