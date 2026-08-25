# Repository agent guide

This repository is a security-sensitive desktop installer.

- Keep user-facing documentation in English and update `README.ru.md` when the
  installation workflow or visible result changes.
- Use Bash only; do not add runtime dependencies without maintainer approval.
- Keep every upstream version and SHA-256 in `config/versions.env`.
- Never commit real backups, home-directory paths, tokens, keys, cookies,
  portal permissions, dconf databases, or full desktop launchers.
- Treat extension patches as version-specific. Refresh and test them against
  clean official archives.
- Preserve automatic backup and rollback before any destructive installation
  step.
- Keep removal targets explicit and validated.
- Run `tests/test-repository.sh`, `tests/test-patches.sh`, and
  `install.sh --dry-run` after relevant changes.
- Update `CHANGELOG.md`, `THIRD_PARTY.md`, and compatibility docs when pinned
  sources or behavior change.
