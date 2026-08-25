# Complete settings reference

The canonical machine-readable values live in `config/`. This document explains
the choices that affect appearance and behavior. Only lower-dock settings are
applied inside Blur My Shell; its top-panel and overview settings are left
untouched.

## Dash to Dock

| Setting | Value | Effect |
| --- | --- | --- |
| Position | bottom, centered, not extended | Floating capsule |
| Icon size | 40 px | Consistent optical scale |
| Background | `#202020`, opacity `0.24` | Neutral dark tint without a fixed color accent |
| Transparency mode | fixed | Stable material density |
| Compact mode | enabled | Tight vertical geometry |
| Bottom offset | 6 px custom CSS + 4 px built in | Approximately 10 px from screen edge |
| Running indicator | one dot | Minimal state indicator |
| Autohide | enabled | Dock remains edge-reachable |
| Intellihide | maximized windows, primary only | Primary dock remains visible on a free desktop |
| Fullscreen reveal | enabled | Bottom edge can reveal the dock |
| Pressure requirement | disabled | Immediate edge reveal |
| Click action | raise the application | Predictable single-click behavior |
| Scroll action | none | No accidental workspace switching |
| Numeric hotkeys and overlay | disabled | No Super+number takeover |
| Multi-monitor | enabled | One dock per display |
| Isolate monitors | enabled | Running apps follow their window display |
| Trash and favorites | primary only, local patch | Clean secondary docks |

## Blur My Shell

| Setting | Value |
| --- | ---: |
| Dynamic dock blur | enabled |
| Sigma | 30 |
| Brightness | 0.82 |
| Corner radius | 18 |
| Static blur | disabled |
| Override Dash to Dock background | disabled |
| Pipeline | `pipeline_default_rounded` |

The neutral Dash to Dock layer remains visible over the dynamic blur. Wallpaper
color may naturally pass through the material; the dock itself adds no plum or
pink tint.

## Flourish

| Motion | Value |
| --- | --- |
| Profile | custom |
| Hover scale | 1.22 |
| Neighbor scale | 1.08 across two neighbors |
| Hover lift | 5 px |
| Hover duration | 280 ms, `ease-out-back` |
| Press | squash, intensity 0.85, 170 ms |
| Launch | bounce, intensity 0.45, speed 1.0 |
| Repeats | disabled |
| Safety timeout | 900 ms |

The stored measured icon size is 40 px and the measured hover budget is 9 px.

## Workspaces and Just Perfection

- dynamic workspaces: disabled;
- number of workspaces: one;
- workspace popup: hidden;
- workspace strip and peek: hidden;
- workspace items in the app grid: hidden.

## WhiteSur

The base and pink variants are installed, and `WhiteSur-dark` becomes active.
The installer overlays:

- `vk-messenger.svg`;
- `express.svg`;
- `codex-desktop.svg`.

If matching user launchers exist, their `Icon=` keys are normalized to
`vk-messenger`, `express`, and `thunderbird-nightly`. Codex Desktop already uses
the themed name in its system launcher.

## Favorites

The exact reference favorites are stored in `config/favorite-apps.gvariant`.
They are applied by default and can be preserved on the target system with
`--keep-favorites`.
