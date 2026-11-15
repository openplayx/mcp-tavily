# mcp-tavily

OpenPlayX 的联网搜索 MCP 服务，后端用 Tavily，跑在 Cloudflare Workers 上：`https://mcp-tavily.openplayx.com/mcp`。

App 把它当作**预置的外部能力**内置（`lib/services/external/external_presets.dart`）：首次启动时自动添加到「AI → 外部能力」，AI 看到的工具名是 `mcp_tavily_web_search`。用户删掉后不会再自动加回来。

## 接口

| 路径 | 说明 |
|---|---|
| `POST /mcp` | MCP Streamable HTTP（只返回 JSON，无状态，不发 `Mcp-Session-Id`）。支持 `initialize`、`ping`、`tools/list`、`tools/call` 和通知；协议版本 2025-11-25 / 2025-06-18 / 2025-03-26 |
| `GET /mcp` | 405，不提供服务器主动推送的流 |
| `GET /health` | `{"ok":true,"search":<是否已配置并开启>}` |

认证：`Authorization: Bearer <App 的匿名安装 ID>`，格式为 16–64 位 `[A-Za-z0-9-]`。它不是密钥，只用来按安装计算额度。

### 工具 `web_search`

参数：`query`（1–300 字）、`count`（1–10，默认 8）、`time_range`（`day` / `week` / `month` / `year`）。
返回：`{"results":[{title,url,snippet?,date?}],"cached":bool}`。

业务错误是 `isError: true` 的工具结果，`structuredContent` 为 `{"error":{status,code,message,retryable,detail?}}`，和其他 mcp-* 服务一致：

| code | 含义 |
|---|---|
| `quota_exceeded`（429） | 今天的免费次数用完了，`detail.scope` 为 device / ip / global；App 没有其他搜索后备，AI 会告诉用户次数已用完 |
| `service_unavailable`（503） | 搜索被关闭、Tavily key 没配置或失效，或者 Tavily 账户额度用完 |
| `upstream_unavailable` / `upstream_changed`（502） | Tavily 出错 |
| `invalid_request`（400） | 参数不合法 |

## 设计

- **Tavily key 只在这里**：Worker secret `TAVILY_API_KEY`，不进仓库，也不在 App 里。
- **额度**（按 UTC 自然日）：每个安装 `DEVICE_DAILY_LIMIT`、每个 IP `IP_DAILY_LIMIT`、全局 `GLOBAL_DAILY_LIMIT`。计数放在一个 SQLite Durable Object（`Quota`）里，准确且原子；上游失败会退回额度。IP 只存哈希值。
- **缓存**：相同的查询（不区分大小写）、count 和 time_range 走边缘缓存 6 小时，不消耗额度，也不花钱。
- **开关**：`SEARCH_ENABLED` 改成 `"false"` 后重新部署即可关闭。
- 安装 ID 可以随意更换，所以按安装的额度只是软限制。真正控制费用的是全局上限，再加上在 Tavily 后台设置的消费上限。
- 改了工具定义时，要同步修改 App 里打包的那份定义（`ExternalPresets.tavily.toolDefs`）；App 的 live 测试会比对两边是否一致。

## 开发与部署

```bash
npm install
npm run smoke        # 本地端到端：wrangler dev + 模拟 Tavily，小额度
npx wrangler deploy  # 部署到 mcp-tavily.openplayx.com（自定义域名，自动配置 DNS 和证书）
npx wrangler secret put TAVILY_API_KEY   # 或在控制台 Settings → Variables and Secrets 添加
npx wrangler tail    # 实时日志
```

修改额度：改 `wrangler.jsonc` 里的 `vars`，然后重新部署，App 不用发版。
