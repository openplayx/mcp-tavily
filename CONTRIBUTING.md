# Contributing

Thanks for your interest. Bug reports, fixes and small improvements are welcome.

## Issues

- Search existing issues first.
- For bugs, include the commit, the request you sent and the response you got.
  Remove tokens, install IDs and IP addresses before posting.
- Security problems: do **not** open a public issue, see [SECURITY.md](SECURITY.md).

## Pull requests

1. Open an issue first for anything larger than a small fix, so we can agree
   on the approach.
2. Keep changes focused; one topic per pull request.
3. Run the local end-to-end test before pushing:

   ```bash
   npm install
   npm run smoke
   ```

4. Update the README in both languages (`README.md` and `README.zh-CN.md`)
   when behaviour, configuration or tools change.
5. Tool names, arguments and error codes are a contract with MCP clients. When
   the tool definition changes, the copy bundled in the OpenPlayX app must
   change too.

By contributing you agree that your contribution is licensed under this
repository's license.
