# GNOME macOS Dock

<div align="center">

**A reproducible, macOS-inspired GNOME dock with real blur, per-monitor app
filtering, hover magnification, and a curated WhiteSur icon theme.**

[Русская версия](README.ru.md)

[![CI](https://github.com/edwardgushchin/gnome-macos-dock/actions/workflows/ci.yml/badge.svg)](https://github.com/edwardgushchin/gnome-macos-dock/actions/workflows/ci.yml)
[![Latest release](https://img.shields.io/github/v/release/edwardgushchin/gnome-macos-dock)](https://github.com/edwardgushchin/gnome-macos-dock/releases)
[![License: GPL-3.0](https://img.shields.io/github/license/edwardgushchin/gnome-macos-dock)](LICENSE)
[![GNOME 46–50](https://img.shields.io/badge/GNOME-46--50-4A86CF?logo=gnome)](docs/COMPATIBILITY.md)
[![Community standards](https://img.shields.io/badge/community-standards%20100%25-brightgreen)](CONTRIBUTING.md)

![GNOME macOS Dock desktop preview](assets/screenshots/desktop-preview.png)

</div>

## Why this repository exists

This project turns a carefully tuned live GNOME desktop into a reviewable and
repeatable installation. It does not ship an opaque home-directory archive.
Instead, it records upstream versions and checksums, stores the small local
patches, exports every relevant setting, and applies everything only after
creating a timestamped backup.

The scope is deliberately limited to the lower dock, its one-workspace
presentation, and the icon theme. Existing top-panel and unrelated GNOME
preferences are preserved.

The result is a compact floating dock that keeps the useful parts of macOS Dock
behavior while fitting a multi-monitor GNOME workflow.

## Highlights

- **Neutral frosted material:** real dynamic blur, `#202020` tint at `0.24`
  opacity, 18 px corners, and a 10 px visual gap from the screen edge.
- **Consistent 40 px icons:** WhiteSur-dark plus project-owned SVGs for VK
  Messenger, eXpress, and Codex Desktop.
- **Responsive motion:** smooth hover magnification with neighboring icons and
  a single short launch bounce instead of repeated jumping.
- **Main-monitor intelligence:** favorites, Trash, and removable media stay on
  the primary display.
- **Windows-style secondary docks:** every secondary monitor shows only
  applications that currently have windows on that monitor.
- **Predictable hiding:** the primary dock remains visible until a maximized or
  fullscreen window needs the space; secondary docks use edge-triggered
  autohide.
- **One workspace:** workspace UI and switching affordances are removed from
  this preset.
- **Safe by default:** no `sudo`, pinned HTTPS sources, SHA-256 verification,
  automatic backup, automatic rollback on installation failure, and a
  dedicated restore command.

![Dock close-up](assets/screenshots/dock-close-up.png)

## Quick start

Review the scripts, then run:

```bash
git clone https://github.com/edwardgushchin/gnome-macos-dock.git &&
cd gnome-macos-dock &&
./install.sh
```

The installer asks for confirmation. For an unattended installation:

```bash
./install.sh --yes
```

Sign out of GNOME and sign back in once, then verify the result:

```bash
./status.sh
```

### Requirements

- GNOME Shell 46–50; GNOME 50.4 on Wayland is the reference environment.
- `bash`, `curl`, `git`, `bsdtar`, `patch`, `sha256sum`, `python3`, `dconf`,
  `gsettings`, `glib-compile-schemas`, and `gnome-extensions`.
- An internet connection for the pinned upstream archives and WhiteSur commit.

The installer never installs system packages and never invokes `sudo`.

## What gets installed

| Component | Pinned version | Purpose |
| --- | ---: | --- |
| [Dash to Dock](https://extensions.gnome.org/extension/307/dash-to-dock/) | 105 | Dock layout, autohide, indicators, and monitor isolation |
| [Blur My Shell](https://extensions.gnome.org/extension/3193/blur-my-shell/) | 72 | Dynamic background blur |
| [Flourish](https://github.com/Orsso/flourish) | 1.0.0 | Hover magnification and launch feedback |
| [Just Perfection](https://extensions.gnome.org/extension/3843/just-perfection/) | 36 | One-workspace presentation and small panel adjustments |
| [WhiteSur icon theme](https://github.com/vinceliuice/WhiteSur-icon-theme) | pinned commit | Base, dark, light, and pink icon variants |

The upstream projects are downloaded from their official locations. Their exact
URLs, commits, hashes, and licenses are documented in [THIRD_PARTY.md](THIRD_PARTY.md).
The three custom WhiteSur-style SVGs and both extension patches live directly
in this repository.

## Safety and rollback

Before changing anything, `install.sh` stores:

- the four existing extension directories;
- their complete dconf settings;
- enabled extensions, favorites, workspace mode, and active icon theme;
- all existing `WhiteSur*` theme directories;
- any user launchers whose icon names are adjusted.

Backups are private to the current user under:

```text
${XDG_STATE_HOME:-~/.local/state}/gnome-macos-dock/backups/
```

Restore the newest backup:

```bash
./restore.sh latest
```

Backups are deliberately retained after restore.

## Installer options

```text
--yes                    Skip the confirmation prompt
--dry-run                Verify sources, hashes, SVGs, and patches only
--force-gnome-version    Continue outside GNOME 46–50
--keep-favorites         Keep the target system's current favorites
--skip-icons             Leave the target system's icon theme unchanged
--main-monitor NAME      Pin the main dock to a connector such as DP-3
```

Without `--main-monitor`, Dash to Dock follows the target system's primary
display instead of copying a machine-specific connector name.

## Documentation

- [Architecture and local patches](docs/ARCHITECTURE.md)
- [Complete settings reference](docs/SETTINGS.md)
- [Compatibility](docs/COMPATIBILITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Contributing](CONTRIBUTING.md)
- [Release process](RELEASING.md)
- [Security policy](SECURITY.md)
- [Support](SUPPORT.md)

## Contributors

Created and maintained by [Eduard Gushchin](https://github.com/edwardgushchin).
See [AUTHORS.md](AUTHORS.md), the
[GitHub contributors graph](https://github.com/edwardgushchin/gnome-macos-dock/graphs/contributors),
and [THIRD_PARTY.md](THIRD_PARTY.md) for complete upstream attribution.

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and
follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

Repository-owned scripts, documentation, and custom WhiteSur overlays are
available under GPL-3.0. Patches and downloaded upstream components retain
their upstream licenses; see [THIRD_PARTY.md](THIRD_PARTY.md).

Application names and logos are trademarks of their respective owners. This
project is not affiliated with Apple, GNOME, or the referenced application
vendors.
