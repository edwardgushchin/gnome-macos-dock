#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

# The dry run downloads official pinned archives into a temporary directory,
# verifies every checksum, applies both patches, compiles extension schemas,
# validates custom SVG checksums, and confirms that the WhiteSur remote exists.
exec "$ROOT_DIR/install.sh" --dry-run
