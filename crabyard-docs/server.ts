import { serve } from "bun";
import { createStaticHandler } from "./src/server/static";

serve({
  hostname: "0.0.0.0",
  port: Number.parseInt(process.env.PORT || "3000", 10),
  fetch: createStaticHandler("./dist"),
});
