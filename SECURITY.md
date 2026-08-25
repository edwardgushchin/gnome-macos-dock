# Security policy

## Supported versions

Security fixes are provided for the latest release line.

| Release line | Supported |
| --- | --- |
| `1.x` | Yes |
| Pre-release snapshots and older lines | No |

## Reporting a vulnerability

Do not open a public issue, discussion, or pull request for a suspected
vulnerability.

Use [GitHub private vulnerability reporting](https://github.com/edwardgushchin/gnome-macos-dock/security/advisories/new)
and include:

- the project version and affected script or patch;
- the target distribution and GNOME Shell version;
- a clear impact and attack scenario;
- minimal reproduction steps;
- whether the issue involves archive verification, path handling, backup data,
  launcher rewriting, or an upstream component;
- any known mitigation or upstream advisory.

An initial acknowledgement is expected within 72 hours. The maintainer will
validate the report, coordinate with upstream when needed, and provide updates
at least weekly while the report remains active.

Please allow a reasonable remediation period before public disclosure. Credit
will be offered unless the reporter prefers anonymity.

## Scope

This policy covers repository-owned install, backup, restore, status, and CI
tooling; the bundled patches and SVGs; and the way pinned upstream artifacts are
fetched and verified.

Vulnerabilities wholly inside Dash to Dock, Blur My Shell, Flourish, Just
Perfection, WhiteSur, GNOME Shell, or a distribution package should also be
reported to that upstream project. Reports about this repository's integration
or packaging are still welcome here.

## Security design

- The installer does not use `sudo`.
- Extension archives are pinned and verified by SHA-256 before extraction.
- WhiteSur is checked out by an exact Git commit.
- Destructive extension targets are allowlisted.
- Existing state is backed up before replacement.
- Failed installations attempt automatic rollback.
- Backups are created with user-only permissions and are never suitable for
  publication.
