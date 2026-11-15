#!/usr/bin/env bash
# Local end-to-end check of the MCP endpoint: wrangler dev against a mock
# Tavily, with small quotas (3 per install, 5 global).
set -euo pipefail
cd "$(dirname "$0")/.."
PORT_MOCK=8799 PORT_DEV=8798
PORT=$PORT_MOCK node scripts/mock-tavily.mjs & MOCK=$!
npx wrangler dev --port $PORT_DEV --local --persist-to .wrangler/smoke-state \
  --var TAVILY_API_KEY:test-key --var TAVILY_ENDPOINT:http://127.0.0.1:$PORT_MOCK/search \
  --var DEVICE_DAILY_LIMIT:3 --var GLOBAL_DAILY_LIMIT:5 >/tmp/mcp-tavily-dev.log 2>&1 & DEV=$!
trap 'kill $MOCK $DEV 2>/dev/null; rm -rf .wrangler/smoke-state' EXIT
B=http://localhost:$PORT_DEV
for _ in $(seq 1 60); do curl -sf $B/health >/dev/null && break; sleep 1; done

rpc() { # token, json-rpc body
  curl -s -X POST $B/mcp -H "authorization: Bearer $1" -H 'content-type: application/json' \
    -H 'accept: application/json, text/event-stream' -d "$2" -w ' [%{http_code}]'; echo
}
call() { # token, arguments
  rpc "$1" "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"web_search\",\"arguments\":$2}}" \
    | python3 -c 'import sys,json; t=sys.stdin.read(); b,c=t.rsplit(" [",1); r=json.loads(b).get("result",json.loads(b)); s=r.get("structuredContent",r); print(("ERR " + s["error"]["code"] + (" " + json.dumps(s["error"].get("detail")) if s["error"].get("detail") else "")) if r.get("isError") else (str(len(s["results"])) + " results cached=" + str(s["cached"]).lower()) if "results" in s else json.dumps(r))'
}
A=install-aaaaaaaaaaaa
echo "health:     $(curl -s $B/health)"
echo "no token:   $(rpc '' '{"jsonrpc":"2.0","id":1,"method":"ping"}')"
echo "initialize: $(rpc $A '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"t","version":"1"}}}' | cut -c1-140)"
echo "notify:     $(rpc $A '{"jsonrpc":"2.0","method":"notifications/initialized"}')"
echo "tools/list: $(rpc $A '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | grep -o '"name":"[a-z_]*"' | head -1)"
echo "bad args:   $(call $A '{"query":"x","extra":1}')"
echo "search:     $(call $A '{"query":"dart","count":2}')"
echo "fail:       $(call $A '{"query":"fail"}')"
echo "q2:         $(call $A '{"query":"q2","count":1,"time_range":"week"}')"
echo "q3:         $(call $A '{"query":"q3","count":1}')"
echo "device 4th: $(call $A '{"query":"q4","count":1}')"
echo "other:      $(call install-bbbbbbbbbbbb '{"query":"q5","count":1}')"
echo "other2:     $(call install-bbbbbbbbbbbb '{"query":"q6","count":1}')"
echo "global 6th: $(call install-cccccccccccc '{"query":"q7","count":1}')"
echo "cache hit:  $(call install-cccccccccccc '{"query":"DART","count":2}')"
echo "unknown:    $(rpc $A '{"jsonrpc":"2.0","id":3,"method":"nope"}')"
echo "GET /mcp:   $(curl -s -o /dev/null -w '%{http_code}' $B/mcp)"
