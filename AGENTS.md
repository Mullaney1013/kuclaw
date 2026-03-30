# Kuclaw Agent Rules

For this repository, always load and follow:
[$using-superpowers](/Users/Y/.codex/superpowers/skills/using-superpowers/SKILL.md)

Apply it at the start of each new task or conversation before analysis, questions, or code changes.

## Git Workflow

Use automatic commit + push for Codex-authored code changes:

- After Codex modifies code and relevant verification succeeds, automatically run `git add`, `git commit`, and `git push`.
- Relevant verification means at least one applicable check passes, such as a build, a test run, or explicit user confirmation that retesting passed.
- Do not auto-commit or auto-push pure design/Figma-only changes with no repository file edits.
- If there are unrelated uncommitted changes not made by Codex, stop and ask before committing or pushing.
- Push to the current working branch. If the current branch is `main`, push `main`.
