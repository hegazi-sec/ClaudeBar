# UsageBar

A tiny macOS menu bar ring that shows how much of your Claude plan you've used.

- **Ring color** follows your most-used limit: green under 70%, orange 70–89%, red 90%+, gray when there's no data.
- **Click it** to see each limit with its reset time: 5-hour, weekly, and per-model weekly (such as Fable).
- Refreshes every minute. **Refresh** (⌘R) updates right away.

Works with Claude Pro, Max and Team plans when you're signed in to Claude Code. People who use an API key have no plan limits, so there is nothing to show.

## Install

Needs macOS 13 or later and Apple's free command line tools (the script offers to install them).

```sh
git clone https://github.com/hegazi-sec/usagebar.git
cd usagebar
./install.sh
```

This builds the app on your Mac, puts it in `~/Applications`, and starts it at login. Because you build it yourself, macOS doesn't show an "unverified developer" warning.

Run `./install.sh` again to update, or `./install.sh uninstall` to remove it.

## How it works

UsageBar reads the sign-in that Claude Code saves in your macOS Keychain (the item named `Claude Code-credentials`). It uses it to ask Anthropic's usage endpoint for your limits, the same numbers the Claude app shows. The token is only sent to `api.anthropic.com` and is never written to disk. Everything is in one file, [`UsageBar.swift`](UsageBar.swift), so you can read exactly what it does.

The first time, macOS may ask whether to allow access to that Keychain item. Choose **Always Allow**.

## Caveats

- The usage endpoint is **not documented** by Anthropic. An update on their side can break UsageBar until it's fixed here.
- If the ring stays gray, click it. The menu says what's wrong; usually you need to open Claude Code once so it can refresh your sign-in.

## Development

```sh
swiftc -O UsageBar.swift -o /tmp/UsageBar && /tmp/UsageBar --selftest   # parsing and color checks
/tmp/UsageBar --print                                                      # one live fetch, printed
```

Not affiliated with Anthropic.
