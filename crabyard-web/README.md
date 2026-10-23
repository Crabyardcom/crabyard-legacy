# Crabyard Web

The [Crabyard](https://crabyard.dev) marketing site and verified CLI installers. Standalone repository: [Crabyardcom/crabyard-web](https://github.com/Crabyardcom/crabyard-web).

```sh
bun install --frozen-lockfile
bun run dev
```

Next.js serves the local site at `http://localhost:3000`. Edit pages in `src/app`, shared sections in `src/components`, and installers in `public`.

```sh
bun run check
bun run build
docker build -t crabyard-web .
```

The Dockerfile builds and serves Next.js standalone output from this repository's root. Deploy with port 3000 (or Railway's `PORT`) and `/` as the health check. The API and documentation have separate repositories and deployments.

Installers use the Crabyard API release proxy and require per-archive `.sha256` release sidecars. `CRABYARD_API_URL`, `CRABYARD_INSTALL_DIR`, and `CRABYARD_VERSION` override the API URL, install destination, and release tag. The CLI release source is [crabyard-cli](https://github.com/Crabyardcom/crabyard-cli).
