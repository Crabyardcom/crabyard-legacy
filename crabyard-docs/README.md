# Crabyard Documentation

The [Crabyard documentation](https://docs.crabyard.dev), built with Astro and Starlight. Standalone repository: [Crabyardcom/crabyard-docs](https://github.com/Crabyardcom/crabyard-docs).

```sh
bun install --frozen-lockfile
bun run dev
```

Edit Markdown and MDX pages in `src/content/docs`. Navigation and site metadata live in `astro.config.mjs`.

```sh
bun test
bun run build
bun run start
docker build -t crabyard-docs .
```

The Dockerfile builds static pages and serves them with Bun on Railway's `PORT` or port 3000. Use this repository's root as the build context and `/` for the health check. The static server supports GET and HEAD and confines requests to the built `dist` directory.

The generator lives in [crabyard-cli](https://github.com/Crabyardcom/crabyard-cli); its source templates live in [crabyard-templates](https://github.com/Crabyardcom/crabyard-templates). Keep command examples and generated file descriptions aligned with those repositories.
