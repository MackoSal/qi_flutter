---
name: commit-message
description: Write or review a Git commit subject for this repository. Use when preparing, amending, or evaluating a commit message.
---

# Commit message guidance

Write a short, single-line Conventional Commit subject in the form `type(scope): imperative summary`. Omit the scope when the type already makes the change clear.

## Base the subject on the commit

Before choosing a subject, inspect the staged diff and enough recent history to understand the project's terminology. Describe the meaningful change that the commit actually contains. The subject becomes a permanent index to the project history, so it must remain accurate and understandable to someone who never saw the conversation that led to it.

Do not describe an intention, request, explanation, or earlier state unless the diff demonstrates it. In particular, avoid words such as “restore”, “fix”, or “revert” when the commit does not visibly perform that action. If a conversation says that something was previously wrong, verify that claim against the parent commit and the current diff before including it in the subject.

For documentation commits, name the documentation outcome (for example, `docs: improve template onboarding`) rather than a presumed language transition or conversational context.

## Quick review

- Does the subject describe the staged diff, rather than the user's request or the work session?
- Would it still make sense when read alone in `git log` months later?
- Does its verb accurately describe what changed?
- Is it concise, imperative, and consistent with Conventional Commits?

If any answer is no, revise the subject before committing or amending.
