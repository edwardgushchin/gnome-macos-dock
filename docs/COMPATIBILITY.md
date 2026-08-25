# Compatibility

| Component | Supported by pinned upstream build |
| --- | --- |
| Dash to Dock 105 | GNOME Shell 45–50 |
| Blur My Shell 72 | GNOME Shell 46–50 |
| Flourish 1.0.0 | GNOME Shell 46–50 |
| Just Perfection 36 | GNOME Shell 45–50 |
| Combined preset | GNOME Shell 46–50 |

The reference system is GNOME Shell 50.4 on Wayland with an NVIDIA GPU and
three monitors. GNOME 46–49 are accepted from upstream metadata and CI-level
static validation, but the full visual result should be reported by real-session
testers.

X11 may work because the extensions support GNOME Shell rather than a specific
display protocol, but Wayland is the tested path.

The installer exits outside GNOME 46–50 unless
`--force-gnome-version` is supplied. That flag bypasses only the version guard;
it does not make the version supported.
