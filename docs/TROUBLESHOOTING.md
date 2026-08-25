# Troubleshooting

## The extensions are installed but inactive

Sign out of GNOME and sign back in. GNOME Shell on Wayland cannot fully reload
new JavaScript extensions in place. Then run:

```bash
./status.sh
```

## The dock blur is missing after login

Confirm that both extensions are active:

```bash
gnome-extensions info dash-to-dock@micxgx.gmail.com
gnome-extensions info blur-my-shell@aunetx
```

Then verify that the startup-race patch exists:

```bash
grep DASH_READY_RETRY_LIMIT \
  ~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/components/dash_to_dock.js
```

Do not repeatedly toggle the extensions before checking `status.sh`; updates may
have replaced the pinned source tree.

## A secondary dock shows favorites or Trash

An extension update likely overwrote `dash.js`. Re-run the matching release of
`install.sh` or restore and install again. `status.sh` checks the patch marker.

## The main dock is on the wrong display

The default follows GNOME's primary display. Set the correct primary monitor in
GNOME Settings, or reinstall with an explicit connector:

```bash
./install.sh --main-monitor DP-1
```

Connector names are system-specific.

## An application ignores the custom icon

Inspect its desktop file. An absolute PNG path bypasses the icon theme:

```bash
grep '^Icon=' ~/.local/share/applications/example.desktop
```

Use a theme name without a path and refresh the desktop database. The installer
already handles known VK, eXpress, and Thunderbird user launchers.

## Restore the previous desktop

```bash
./restore.sh latest
```

If multiple backups exist, pass an explicit backup directory. The restore
command keeps the selected backup and requests one GNOME sign-out/sign-in.

## Reporting a bug

Run `./status.sh`, redact personal paths or application data, and include the
GNOME version, distro, display protocol, monitor layout, and exact project
release in the bug report. Never attach installer backups: they can contain
desktop files and personal application choices.
