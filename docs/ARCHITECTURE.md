# Architecture

The repository separates upstream software, local behavior, and machine state.
That makes every modification reviewable and keeps upgrades intentional.

```text
official pinned archives
        |
        v
SHA-256 verification -----> reject on mismatch
        |
        v
temporary staging tree
        |
        +---- apply version-specific patches
        +---- compile GSettings schemas
        +---- overlay custom WhiteSur SVGs
        |
        v
user extension/icon directories
        |
        +---- load exported dconf presets
        +---- enable extensions in deterministic order
        +---- request one GNOME sign-out/sign-in
```

## Why upstream archives are not vendored

Dash to Dock, Blur My Shell, Flourish, Just Perfection, and WhiteSur remain
independent upstream projects. The installer downloads exact releases or a
specific commit from the official locations and verifies the extension archives
before extraction. This preserves attribution, avoids stale forks, and keeps
the repository focused on the integration work.

The repository does contain everything unique to this preset:

- complete exported settings;
- both source patches;
- all three custom application SVGs;
- checksums and source metadata;
- backup, installation, restore, status, and verification tooling.

## Local patches

### Dash to Dock 105

`patches/dash-to-dock-v105.patch` contains three focused changes:

1. favorites are emitted only by the primary monitor's dock;
2. Trash and removable media are emitted only by the primary dock;
3. intellihide applies only to the primary dock, while secondary docks retain
   edge-triggered autohide;
4. a 6 px CSS margin lifts the floating capsule above the built-in 4 px gap.

Running favorite applications still appear on a secondary display when they
have a window there because the running-app list is filtered separately by
Dash to Dock.

### Blur My Shell 72

`patches/blur-my-shell-v72.patch` fixes a startup race. Dash to Dock can publish
its top-level actor before the child dash and monitor allocation are ready.
Blur My Shell now retries every 100 ms for at most 30 attempts and removes all
pending GLib sources when disabled. The patch is idempotent and tracks every
monitor independently.

## Portability choices

The reference machine used connector `DP-3`. That historical value remains in
the exported Dash to Dock preset, but `install.sh` resets it by default so the
target system follows its own primary display. Pass `--main-monitor NAME` only
when explicit pinning is desired.

Application favorites are reproducible by default. Use `--keep-favorites` on a
machine with a different application set.

Blur My Shell is shared by several GNOME surfaces. The installer resets and
loads only its `dash-to-dock` subtree. Just Perfection is merged without a
global reset and changes only the four workspace presentation keys. Existing
top-panel, overview, app-folder, and unrelated shell preferences are preserved.

## Update policy

Patches are intentionally version-specific. Updating an extension requires:

1. recording the new official URL and checksum;
2. applying the old patch to a clean tree and resolving context changes;
3. running `tests/test-patches.sh`;
4. testing all monitor roles in a real GNOME session;
5. updating compatibility and release notes.

The installer refuses unknown checksums and does not silently fall forward to a
new extension build.
