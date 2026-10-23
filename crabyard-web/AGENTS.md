# Agent instructions

- This standalone repository owns the Next.js marketing site and public CLI installer scripts.
- Run `bun install --frozen-lockfile`, `bun run check`, and `bun run build` after application changes.
- Keep installer changes compatible with Windows PowerShell and POSIX sh. Verify downloaded archives before extraction.
- Keep public claims and examples aligned with `Crabyardcom/crabyard-cli` and `Crabyardcom/crabyard-templates`.
- Build Docker from this repository's root. Keep TypeScript validation enabled.
- Add comments only when they explain a non-obvious constraint; keep them under two lines.
