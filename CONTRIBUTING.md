# Contributing to ClaudeBar

First — **thank you** for taking the time to look at this. ClaudeBar is an open project. Whether you're reporting a bug, suggesting a feature, fixing a typo, or improving the ring, your contribution is genuinely welcome.

## Ways to Contribute

- **Report bugs** — open an [issue](https://github.com/hegazi-sec/ClaudeBar/issues) with reproduction steps. The more detail, the faster the fix.
- **Suggest features** — open an issue with the use case and the problem you're trying to solve.
- **Submit a pull request** — fix a bug, add a feature, or improve the docs.
- **Report endpoint changes** — if Anthropic changes the usage response and ClaudeBar breaks, an issue with the new (redacted) JSON shape helps a lot.

## Branching Strategy

ClaudeBar's public repository is single-branch: **`main`**.

The recommended contributor workflow:

1. **Fork** this repository to your own GitHub account.
2. **Create a feature branch** in your fork (e.g. `feature/dark-ring`, `fix/token-refresh`).
3. **Open a Pull Request** from your feature branch to `main` here.

Release tags (`v1.0.0`, etc.) live on `main`. Each tagged release is a versioned snapshot of the project.

## Development Setup

Needs macOS 13+ and Apple's command line tools (`xcode-select --install`).

```bash
git clone https://github.com/hegazi-sec/ClaudeBar.git
cd ClaudeBar
swiftc -O ClaudeBar.swift -o /tmp/ClaudeBar && /tmp/ClaudeBar --selftest   # parsing and color checks
/tmp/ClaudeBar --print                                                       # one live fetch, printed
./install.sh                                                                 # build, install, restart the menu bar app
```

## Pull Request Checklist

Before opening a PR, please make sure:

- [ ] Your PR targets `main` and comes from a feature branch in your fork.
- [ ] The PR description explains the **why**, not just the **what**.
- [ ] Code changes are **scoped** — no unrelated refactors mixed in.
- [ ] `--selftest` passes, and you ran the app and checked the change in the menu bar.
- [ ] For visual changes, include a **before / after screenshot** of the menu bar.
- [ ] No tokens, Keychain contents, or raw usage responses with account details committed.
- [ ] Commit messages follow the project style (see below).

## Code Style

### Swift

- Keep it to **one file**, `ClaudeBar.swift`, and **no dependencies** beyond AppKit and Foundation. People build this from source, so the build has to stay a single `swiftc` call.
- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) for naming.
- Prefer **early returns** (`guard`) over deep nesting.
- New parsing or formatting logic gets a line in `--selftest`.

### General

- **Don't add backwards-compatibility shims** for code that hasn't shipped yet.
- **Don't add comments** that just restate the code. Add comments for *why* something is unusual or non-obvious.
- **Don't add error handling** for situations that can't happen — but do handle network and Keychain failures, since those happen.

## Commit Messages

- **Short subject line** (≤72 chars), **imperative mood** ("Fix ring color at 70%", not "Fixed" or "Fixes").
- **Body** (optional) — explain context and reasoning when needed, separated by a blank line.

### Example

```
Keep last good numbers when the usage fetch fails

A single failed request turned the ring gray and dropped the menu
entries. Now the previous values stay and the ring goes gray only
until the next successful refresh.
```

## Reporting Bugs

Use the issue template. At minimum, please include:

- **macOS version**
- **ClaudeBar version or commit** (`git rev-parse --short HEAD`)
- **Plan** (Pro / Max / Team)
- **What you did** — steps to reproduce
- **What you expected**
- **What actually happened** — including the message in ClaudeBar's menu
- **Screenshots** of the menu bar if it's a visual issue

## Security Vulnerabilities

**Do not open public issues for security bugs.** Use GitHub's private vulnerability reporting on the repo instead. See [SECURITY.md](SECURITY.md). You'll get an acknowledgement within 48 hours.

## Code of Conduct

Be kind. Be technical. Disagree with ideas, not people. Bad-faith arguments, harassment, or hostility have no place here and will be moderated. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Questions?

Open an issue — no question is too small. Whether you're stuck on setup, exploring the code, or just curious about a design choice, please ask. I'm always happy to help.

— Ahmed Hegazi
