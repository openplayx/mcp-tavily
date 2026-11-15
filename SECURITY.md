# 安全策略

## 报告漏洞

请通过 GitHub 私下报告：打开仓库的 **Security** 页，选择 **Report a vulnerability**。不要用公开的 issue 或 PR 报告安全问题。

请写明受影响的 commit、复现步骤和可能的影响，一般一周内会有初步回复。

范围包括：绕过额度限制、泄露 `TAVILY_API_KEY`、通过 Worker 访问非预期的地址等。

## 支持的版本

只修复 `main` 的最新提交，以及 `mcp-tavily.openplayx.com` 上正在运行的版本。
