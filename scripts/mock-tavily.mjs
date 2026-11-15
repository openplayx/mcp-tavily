// Local stand-in for the Tavily Search API used by scripts/smoke.sh.
import http from "node:http";
let calls = 0;
http
  .createServer((req, res) => {
    let body = "";
    req.on("data", (c) => (body += c));
    req.on("end", () => {
      calls++;
      const { query, max_results } = JSON.parse(body || "{}");
      res.setHeader("content-type", "application/json");
      if (req.headers.authorization !== "Bearer test-key") {
        res.statusCode = 401;
        return res.end("{}");
      }
      if (query === "fail") {
        res.statusCode = 500;
        return res.end("{}");
      }
      res.end(
        JSON.stringify({
          results: Array.from({ length: max_results }, (_, i) => ({
            title: `Result ${i} for ${query}`,
            url: `https://example.com/${i}`,
            content: `snippet ${i}`,
            published_date: "2026-11-01",
          })).concat([{ title: "bad", url: "javascript:alert(1)" }]),
          calls,
        }),
      );
    });
  })
  .listen(Number(process.env.PORT ?? 8799));
