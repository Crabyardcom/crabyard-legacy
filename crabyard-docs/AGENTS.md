# Agent instructions

- This standalone repository owns the Astro/Starlight documentation and Bun static server.
- Run `bun install --frozen-lockfile`, `bun test`, and `bun run build` after changes.
- Keep CLI examples aligned with `Crabyardcom/crabyard-cli`; generated app examples follow `Crabyardcom/crabyard-templates`.
- Document only implemented behavior. Keep prerequisites, platform limits, and environment variable names explicit.
- Static requests must remain confined to `dist`; preserve GET/HEAD support and real 404 responses.
- Add comments only when they explain a non-obvious constraint; keep them under two lines.
