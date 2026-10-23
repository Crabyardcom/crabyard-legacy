import { afterAll, beforeAll, expect, test } from "bun:test";
import { mkdtemp, mkdir, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createStaticHandler } from "./static";

let directory: string;
let handler: ReturnType<typeof createStaticHandler>;
beforeAll(async () => {
  directory = await mkdtemp(join(tmpdir(), "crabyard-docs-test-"));
  await mkdir(join(directory, "guide"));
  await writeFile(join(directory, "index.html"), "home");
  await writeFile(join(directory, "guide/index.html"), "guide");
  await writeFile(join(directory, "404.html"), "missing");
  handler = createStaticHandler(directory);
});
afterAll(async () => {
  await rm(directory, { recursive: true, force: true });
});
test("serves directory pages", async () => {
  const response = await handler(new Request("https://docs.crabyard.dev/guide/"));
  expect(response.status).toBe(200);
  expect(await response.text()).toBe("guide");
});
test("HEAD returns headers without a body", async () => {
  const response = await handler(new Request("https://docs.crabyard.dev/", { method: "HEAD" }));
  expect(response.headers.get("content-length")).toBe("4");
  expect(await response.text()).toBe("");
});
test.each(["/%2e%2e%2fsecret", "/..%2fsecret"])("rejects encoded traversal %s", async (path) => {
  const response = await handler(new Request(`https://docs.crabyard.dev${path}`));
  expect(response.status).toBe(404);
});
test("rejects malformed URL encoding", async () => {
  expect((await handler(new Request("https://docs.crabyard.dev/%ZZ"))).status).toBe(400);
});
test("unsupported methods are rejected", async () => {
  expect((await handler(new Request("https://docs.crabyard.dev/", { method: "POST" }))).status).toBe(405);
});
test("missing assets keep a 404 status", async () => {
  const response = await handler(new Request("https://docs.crabyard.dev/missing"));
  expect(response.status).toBe(404);
  expect(await response.text()).toBe("missing");
});
