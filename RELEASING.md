# Releasing

1. Update `PROJECT_VERSION` in `config/versions.env` and the root `VERSION`.
2. Update `CHANGELOG.md`, compatibility notes, and any changed upstream hashes.
3. Run:

   ```bash
   ./tests/test-repository.sh
   ./tests/test-patches.sh
   ./tests/test-install-flow.sh
   ./install.sh --dry-run
   ```

4. Test installation and restore in a disposable GNOME user account.
5. Test primary and secondary docks on a multi-monitor GNOME session.
6. Commit with `Release vX.Y.Z`, create a signed or annotated `vX.Y.Z` tag,
   push the commit and tag, and create a GitHub release from the matching
   changelog entry.
7. Confirm CI, release links, Community Standards, and the security page.

Never regenerate an existing version tag or replace an archive checksum without
a new release and an explicit security explanation.
