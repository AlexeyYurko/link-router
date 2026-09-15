**LinkRouter**

I keep work and personal stuff in different browsers. Copy-pasting links between them got old, so I made a small macOS tool that picks the right browser (and profile) based on where the link came from and what the URL is. Rules live in a plain JSON file.

### How it works

LinkRouter registers as the default handler for `http`/`https`. When you click a link, macOS hands the URL over as an Apple Event (and starts the app if it isn’t already running). Then it:

1. Figures out which app sent the link.
2. Runs the URL through your rules (first match wins).
3. Opens the target browser, optionally with a specific profile, using `open`.
4. Stays running in the background (no Dock icon, no menu bar) so later clicks are instant. Quit with `LinkRouter --quit`.

No matching rule → falls back to whatever you set as `fallback`.

### Requirements

- macOS 13+ (Apple Silicon or Intel)
- Swift (Xcode or just Command Line Tools: `xcode-select --install`)

### Install

```sh
./scripts/install.sh   # or: make install
```

Builds the app, drops it in `/Applications/LinkRouter.app`, sets it as the default browser, and launches it. First link you click after that goes through LinkRouter.

### Config

Lives at `~/.config/link-router/config.json` (created on first run). There’s an example at `config.example.json`. It reloads on every click, so you can edit rules and the next link already uses them.

```json
{
  "fallback": {
    "browser": "Safari"
  },
  "rules": [
    {
      "name": "GitHub in Chrome",
      "match": { "host": "github.com" },
      "target": { "browser": "Chrome" }
    },
    {
      "name": "Slack links to work profile",
      "source": ["com.tinyspeck.slackmacgap"],
      "target": { "browser": "Chrome", "profile": "Work" }
    },
    {
      "name": "Work sites to work profile",
      "match": { "host": "*.atlassian.net" },
      "target": { "browser": "Chrome", "profile": "Work" }
    }
  ]
}
```

#### `target.browser`

Friendly names work (case-insensitive): `Chrome`, `Chrome Canary`, `Chrome Beta`, `Chrome Dev`, `Firefox`, `Firefox Developer Edition`, `Firefox Nightly`, `Safari`, `Brave`, `Brave Beta`, `Microsoft Edge`, `Edge Beta`, `Edge Canary`, `Vivaldi`, `Opera`, `Yandex`, `Chromium`. Bundle IDs are fine too. Paths with a `/` (e.g. `/Applications/Firefox.app`) get opened with `open -a`.

`"", "none", "null", or "suppress"` just eats the link.

#### `match`

- `host` - matches the host and any subdomain (`github.com` also hits `api.github.com`). `*.` prefix works the same. Case-insensitive.
- `cwd` - directory path. Matches if the request came from that folder or below. Only useful with the CLI (`--route`); normal link clicks don’t carry a folder.
- `prefix` - URL starts with this (case-insensitive).
- `regex` - full URL against an `NSRegularExpression` (case-insensitive). Bad pattern = rule never matches.
- Leave `match` out and the rule applies to any URL (handy with `source`).

#### `source`

List of sender bundle IDs. Rule only fires for links from those apps.

#### Profiles

- Chromium family (Chrome, Brave, Edge, etc.): `profile` is the friendly name from `Local State`, turned into `--profile-directory=`. `Default` / `Profile N` work as-is.
- Firefox: name from `profiles.ini` (`open -no-remote -P <name>`).
- Safari and everything else ignore it.

Rules run top to bottom. Put specific ones first.

#### Finding bundle IDs

Every route logs the source. Easiest way:

```sh
grep source= ~/Library/Logs/LinkRouter.log
```

Click something in Slack → you’ll see `source=com.tinyspeck.slackmacgap`. Without clicking:

```sh
osascript -e 'id of app "Slack"'     # app has to be running
mdls -raw -name kMDItemCFBundleIdentifier /Applications/Slack.app
```

Common ones: `com.tinyspeck.slackmacgap`, `com.tdesktop.Telegram`, `net.whatsapp.WhatsApp`, `md.obsidian`, `com.raycast.macos`, `dev.zed.Zed`, `com.google.Chrome`, `org.mozilla.firefox`.

Source detection is best-effort. Sometimes macOS routes through Launch Services and the original sender is gone; the log is what actually got used.

### Logs

Everything goes to `~/Library/Logs/LinkRouter.log` (config path, which rule hit or fallback, exact `open` command). Query strings and fragments are stripped so tokens don’t end up in the file. Permissions are owner-only. `--dry-run` still prints the full URL to stdout.

### CLI

```sh
LinkRouter --route "https://github.com/AlexeyYurko"                 # route + open
LinkRouter --route "https://example.com" --source com.tinyspeck.slackmacgap --dry-run  # preview only
LinkRouter --route "$URL" --cwd "$PWD"                              # respect match.cwd
LinkRouter --quit                                                   # kill the background process
LinkRouter --set-default                                           # re-register as default browser
```

`--cwd` defaults to the process’s working directory, so a terminal invocation already knows where it was run from. To pretend it’s a normal click, pass `--cwd /`.

Example rule that sends GitHub links from this repo to Firefox and everything else to Chrome:

```json
{
  "name": "Repo links",
  "match": { "host": "github.com", "cwd": "/Volumes/Work/link-router" },
  "target": { "browser": "Firefox" }
}
```

### Switching back

1. `LinkRouter --quit` (or `pkill -x LinkRouter`)
2. System Settings → Desktop & Dock → Default web browser → pick something else

Quitting alone isn’t enough—macOS keeps sending links until you change the default. After that there’s nothing left running: no launch agent, no daemon. Delete `/Applications/LinkRouter.app` if you want it gone.

### Icon

Placeholder at `Resources/AppIcon.icns`. Drop a 1024×1024 `AppIcon.png` in the repo root and:

```sh
make icon               # builds the .icns
make install            # rebuild + install with the new icon
```

Opaque sources are automatically given macOS-style rounded corners (needs `magick`); supply a PNG with an alpha channel if you want to control the shape yourself. Icons are quantized with `pngquant` when available to keep the bundle small.

Uses `sips` + `iconutil`. Referenced in `Resources/Info.plist` via `CFBundleIconFile`.

### Distributing

`make dist` builds the app and produces `dist/LinkRouter-<version>.zip` plus a `.sha256` checksum (version comes from `Resources/Info.plist`). Upload to a GitHub release:

```sh
gh release create v<version> dist/LinkRouter-<version>.zip dist/LinkRouter-<version>.zip.sha256
```

Releases are ad-hoc signed (no Apple Developer account needed). People downloading the zip pass Gatekeeper with a one-time System Settings → Privacy & Security → "Open Anyway"; building from source skips that step entirely.

### Development

```sh
make build     # swift build
make test      # swift run RouterTests
make icon      # generate AppIcon.icns
make install   # build + install + set default
make dist      # zip the app for release (dist/LinkRouter-<version>.zip)
make clean
```

Layout:

- `Sources/RouterCore` - pure Foundation: config, matching, profiles, launching. Tested.
- `Sources/LinkRouter` - the actual app (Apple Events, source detection, CLI).
- `Sources/RouterTests` - simple assertion harness (no XCTest, works with CLT).
- `Resources/Info.plist` - bundle ID, `LSUIElement`, URL scheme registration.
- `scripts/` + `Makefile` - the usual build/install plumbing.

Logging goes to stderr; stdout is for actual output.

### Environment

- `LINK_ROUTER_CONFIG` - point at a different config file.

### License

MIT - see [LICENSE](LICENSE).
