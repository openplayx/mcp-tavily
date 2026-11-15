# 参与贡献

欢迎提交问题报告、修复和小的改进。

## Issue

- 先搜索已有的 issue。
- 报告 bug 时请写明 commit、请求内容和收到的响应；贴出前去掉 token、安装 ID 和 IP。
- 安全问题**不要**公开提 issue，见 [SECURITY.md](SECURITY.md)。

## Pull request

1. 较大的改动请先开 issue 讨论方案。
2. 一个 PR 只做一件事。
3. 推送前运行本地端到端测试：

   ```bash
   npm install
   npm run smoke
   ```

4. 行为、配置或工具有变化时同步更新 README。
5. 工具名、参数和错误码是和 MCP 客户端之间的约定；修改工具定义时，OpenPlayX App 里打包的那份定义也要同步改。

提交贡献即表示你同意按本仓库的许可证授权你的贡献。
