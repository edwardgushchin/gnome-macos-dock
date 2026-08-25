# Contributing to GNOME macOS Dock

Thank you for helping make this preset safer, more portable, and easier to
maintain.

## Before you start

- Read and follow the [Code of Conduct](CODE_OF_CONDUCT.md).
- Search existing [issues](https://github.com/edwardgushchin/gnome-macos-dock/issues)
  and [discussions](https://github.com/edwardgushchin/gnome-macos-dock/discussions).
- Use Discussions for setup questions and visual ideas.
- Report suspected vulnerabilities privately according to
  [SECURITY.md](SECURITY.md).
- Open an issue before changing the supported GNOME range, replacing an
  extension, or redesigning backup and restore behavior.

## Development setup

Clone your fork and create a focused branch from `main`:

```bash
git clone https://github.com/YOUR-USER/gnome-macos-dock.git
cd gnome-macos-dock
git switch -c topic/short-description
```

No production dependency manager is used. Local validation requires Bash,
ShellCheck, curl, git, bsdtar, patch, sha256sum, and xmllint.

## Required checks

Run:

```bash
./tests/test-repository.sh
./tests/test-patches.sh
./tests/test-install-flow.sh
./install.sh --dry-run
```

When changing installer behavior, also test installation and restore in a
disposable GNOME user account. Visual or monitor-related changes require a real
GNOME session report with the shell version, display protocol, and topology.

## Extension patches

- Keep patches minimal and tied to one exact upstream version.
- Generate them from a clean official archive.
- Preserve upstream style and license.
- Explain why a regular setting cannot provide the behavior.
- Update the version, checksum, architecture notes, tests, and changelog
  together.

Do not silently make a patch apply with fuzz to a newer version.

## Icon contributions

SVGs must:

- be source vectors rather than traced raster wrappers;
- match WhiteSur geometry and optical weight at the dock's 40 px size;
- use a 128 × 128 view box;
- retain safe internal spacing and legibility on dark backgrounds;
- pass XML validation and include an updated SHA-256 manifest entry;
- avoid embedding raster data, scripts, external URLs, or metadata.

Attach a 40 px comparison against several existing WhiteSur icons.

## Commits and pull requests

- Write commit messages and public repository text in English.
- Keep each commit reviewable and free of unrelated formatting.
- Link an issue with `Fixes #123`, `Closes #123`, or `Refs #123` when relevant.
- List exact verification commands in the pull request.
- Update both READMEs when user-facing installation or behavior changes.
- Never include secrets, full backups, personal desktop files, absolute home
  paths, generated caches, or unredacted logs.

By contributing, you agree that your work will be distributed under the
path-appropriate licenses described in [THIRD_PARTY.md](THIRD_PARTY.md).
