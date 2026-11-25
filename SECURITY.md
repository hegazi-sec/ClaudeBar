# Security Policy

ClaudeBar reads your Claude Code sign-in token from the macOS Keychain, so reports of vulnerabilities are treated as a priority and triaged ahead of normal feature work.

## Supported Versions

Only the latest release receives patches.

| Version | Supported |
|---------|-----------|
| 1.0.x   | Yes       |
| < 1.0   | No        |

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Instead, report privately using GitHub's [private vulnerability reporting](https://github.com/hegazi-sec/ClaudeBar/security/advisories/new) feature on this repository.

### What to Expect

- **Acknowledgement** within 48 hours
- **Status update** within 7 days
- **Fix released** within 30 days for high-severity issues, sooner for critical
- **Credit** in the release notes (unless you prefer to remain anonymous)

## In Scope

Reports are welcome for:

- The sign-in token leaving the process anywhere other than `api.anthropic.com` (logs, disk, other hosts)
- Ways for another app or user to read the token through ClaudeBar
- Problems in `install.sh` (for example unsafe paths, or files written with loose permissions)
- Anything that lets a network response make ClaudeBar run code or crash in an exploitable way

## Out of Scope

- Attacks that already require control of your macOS user account or Keychain
- Changes to Anthropic's usage endpoint that break the app (open a normal issue)
- Builds you modified yourself

## Sensitive Data Handling

- ClaudeBar reads the `Claude Code-credentials` Keychain item with Apple's `security` tool and keeps the access token in memory only.
- The token is sent only to `https://api.anthropic.com/api/oauth/usage`. Nothing is written to disk.
- ClaudeBar sends no telemetry to anyone.
- Everything lives in one file, [`ClaudeBar.swift`](ClaudeBar.swift), and you build it yourself, so you can check all of the above.

— Ahmed Hegazi
