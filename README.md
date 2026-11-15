# mcp-tavily

English | [简体中文](README.zh-CN.md)

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Web search MCP server for [OpenPlayX](https://github.com/openplayx/openplayx),
backed by Tavily and running on Cloudflare Workers:
`https://mcp-tavily.openplayx.com/mcp`.

The app ships it as a **preset external capability**
(`lib/services/external/external_presets.dart`): on first launch it is added to
**AI → 外部能力** (External capabilities), and the model sees the tool as
`mcp_tavily_web_search`. If the user deletes it, it is not added back.

## Endpoints

| Path | Description |
|---|---|
| `POST /mcp` | MCP Streamable HTTP (JSON responses only, stateless, no `Mcp-Session-Id`). Supports `initialize`, `ping`, `tools/list`, `tools/call` and notifications; protocol versions 2025-11-25 / 2025-06-18 / 2025-03-26 |
| `GET /mcp` | 405; no server-initiated stream |
| `GET /health` | `{"ok":true,"search":<configured and enabled>}` |

Authentication: `Authorization: Bearer <the app's anonymous install ID>`, 16–64
characters of `[A-Za-z0-9-]`. It is not a secret; it only identifies an
installation for quota counting.

### Tool `web_search`

Arguments: `query` (1–300 characters), `count` (1–10, default 8), `time_range`
(`day` / `week` / `month` / `year`).
Returns: `{"results":[{title,url,snippet?,date?}],"cached":bool}`.

Business errors are tool results with `isError: true` and
`structuredContent` `{"error":{status,code,message,retryable,detail?}}`, the
same shape as the other mcp-* services:

| code | Meaning |
|---|---|
| `quota_exceeded` (429) | Today's free searches are used up; `detail.scope` is device / ip / global. The app has no other search fallback, so the assistant tells the user |
| `service_unavailable` (503) | Search is switched off, the Tavily key is missing or invalid, or the Tavily account is out of credits |
| `upstream_unavailable` / `upstream_changed` (502) | Tavily failed |
| `invalid_request` (400) | Invalid arguments |

## Design

- **The Tavily key lives only here**, as the Worker secret `TAVILY_API_KEY`:
  never in the repository, never in the app.
- **Quotas** (per UTC day): `DEVICE_DAILY_LIMIT` per installation,
  `IP_DAILY_LIMIT` per IP and `GLOBAL_DAILY_LIMIT` overall. Counters live in a
  SQLite Durable Object (`Quota`), exact and atomic; upstream failures refund
  the quota. IPs are stored only as hashes.
- **Cache**: identical queries (case-insensitive) with the same count and
  time_range are served from the edge cache for 6 hours, at no quota or cost.
- **Kill switch**: set `SEARCH_ENABLED` to `"false"` and redeploy.
- Install IDs can be changed at will, so the per-install quota is a soft limit.
  Cost is really bounded by the global limit plus the spending limit set in the
  Tavily dashboard.
- When the tool definition changes, update the copy bundled in the app
  (`ExternalPresets.tavily.toolDefs`); the app's live test compares the two.

## Using it from other MCP clients

The hosted instance is meant for the OpenPlayX app and has small quotas. To use
it from other clients, deploy your own (below) and configure:

```json
{
  "mcpServers": {
    "tavily": {
      "type": "http",
      "url": "https://<your-domain>/mcp",
      "headers": { "Authorization": "Bearer <any 16–64 character alphanumeric ID>" }
    }
  }
}
```

## Develop and deploy

Requirements: Node.js 20+; for deployment a Cloudflare account (SQLite-backed
Durable Objects work on the free plan) and a [Tavily](https://tavily.com) API key.

```bash
npm install
npm run smoke        # local end-to-end: wrangler dev + mock Tavily, small quotas
npx wrangler deploy  # deploy (binds the custom domain in wrangler.jsonc routes; DNS and certificate are automatic)
npx wrangler secret put TAVILY_API_KEY   # or add it in the dashboard under Settings → Variables and Secrets
npx wrangler tail    # live logs
```

For your own deployment, change `routes` in `wrangler.jsonc` to a domain on
your Cloudflare account, or remove `routes` and set `workers_dev` to `true` to
use a `*.workers.dev` address. Variables for local development go into
`.dev.vars` (git-ignored).

To change quotas, edit `vars` in `wrangler.jsonc` and redeploy; the app needs
no release.

## Contributing

Issues and pull requests are welcome, see [CONTRIBUTING.md](CONTRIBUTING.md).
Report security problems privately as described in [SECURITY.md](SECURITY.md).

## Disclaimer

This project is not affiliated with Tavily. Results come from Tavily and
third-party websites and are not guaranteed to be accurate. If you deploy your
own instance, you must follow Tavily's terms of service and you pay for its use.

## License

[MIT](LICENSE)
