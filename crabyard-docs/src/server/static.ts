import { file } from "bun";
import { resolve, relative, isAbsolute, join, extname } from "node:path";
import { stat } from "node:fs/promises";

export function createStaticHandler(directory: string) {
  const root = resolve(directory);
  return async (request: Request): Promise<Response> => {
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method Not Allowed", { status: 405, headers: { Allow: "GET, HEAD" } });
    }
    let pathname: string;
    try {
      pathname = decodeURIComponent(new URL(request.url).pathname);
    } catch {
      return new Response("Bad Request", { status: 400 });
    }
    if (pathname.includes("\0") || pathname.includes("\\")) {
      return new Response("Bad Request", { status: 400 });
    }
    const path = resolve(root, `.${pathname}`);
    const fromRoot = relative(root, path);
    if (fromRoot.startsWith("..") || isAbsolute(fromRoot)) {
      return new Response("Not Found", { status: 404 });
    }
    for (const candidate of [path, `${path}.html`, join(path, "index.html")]) {
      if (!(await stat(candidate).catch(() => null))?.isFile()) continue;
      const asset = file(candidate);
      return new Response(request.method === "HEAD" ? null : asset, {
        headers: {
          "Content-Type": asset.type,
          "Content-Length": String(asset.size),
          "X-Content-Type-Options": "nosniff",
          "Cache-Control": extname(candidate) === ".html"
            ? "public, max-age=0, must-revalidate" : "public, max-age=3600",
        },
      });
    }
    const notFound = file(join(root, "404.html"));
    return new Response(request.method === "HEAD" ? null : await notFound.exists() ? notFound : "Not Found", {
      status: 404,
      headers: { "Content-Type": "text/html; charset=utf-8", "X-Content-Type-Options": "nosniff" },
    });
  };
}
