#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

required_files=(
    README.md
    README.ru.md
    LICENSE
    CODE_OF_CONDUCT.md
    CONTRIBUTING.md
    SECURITY.md
    SUPPORT.md
    THIRD_PARTY.md
    CHANGELOG.md
    CITATION.cff
    install.sh
    restore.sh
    status.sh
    tests/test-install-flow.sh
    config/versions.env
    config/dash-to-dock.ini
    config/blur-my-shell.ini
    config/flourish.ini
    config/just-perfection.ini
    patches/dash-to-dock-v105.patch
    patches/blur-my-shell-v72.patch
    icons/apps/codex-desktop.svg
    icons/apps/express.svg
    icons/apps/vk-messenger.svg
    assets/screenshots/desktop-preview.png
    assets/screenshots/dock-close-up.png
    assets/screenshots/social-preview.png
    .github/ISSUE_TEMPLATE/bug_report.yml
    .github/ISSUE_TEMPLATE/feature_request.yml
    .github/PULL_REQUEST_TEMPLATE.md
    .github/workflows/ci.yml
)

for file in "${required_files[@]}"; do
    [[ -f "$file" ]] || {
        printf 'Missing required file: %s\n' "$file" >&2
        exit 1
    }
done

for script in install.sh restore.sh status.sh scripts/*.sh tests/*.sh; do
    bash -n "$script"
done

if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -x install.sh restore.sh status.sh scripts/*.sh tests/*.sh
fi

(
    cd icons
    sha256sum --check SHA256SUMS
)

if command -v xmllint >/dev/null 2>&1; then
    for icon in icons/apps/*.svg; do
        xmllint --noout "$icon"
    done
fi

source config/versions.env
[[ "$(tr -d '\n' < VERSION)" == "$PROJECT_VERSION" ]] || {
    printf 'VERSION and PROJECT_VERSION differ\n' >&2
    exit 1
}

while IFS= read -r action_ref; do
    [[ "$action_ref" =~ @[0-9a-f]{40}$ ]] || {
        printf 'GitHub Action is not pinned to a full commit: %s\n' "$action_ref" >&2
        exit 1
    }
done < <(grep -RhoE 'uses:[[:space:]]+[^[:space:]#]+' .github/workflows |
    awk '{print $2}')

python3 - <<'PY'
from pathlib import Path
import struct

expected = {
    "assets/screenshots/desktop-preview.png": (1920, 1080),
    "assets/screenshots/dock-close-up.png": (1040, 150),
    "assets/screenshots/social-preview.png": (1280, 640),
}

for name, dimensions in expected.items():
    data = Path(name).read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"{name} is not a PNG")
    actual = struct.unpack(">II", data[16:24])
    if actual != dimensions:
        raise SystemExit(f"{name}: expected {dimensions}, got {actual}")
PY

if grep -a -E 'date:(create|modify|timestamp)|/home/' \
    assets/screenshots/*.png; then
    printf 'Screenshot metadata was not fully stripped\n' >&2
    exit 1
fi

if grep -R -n -E \
    '(/home/[[:alnum:]_.-]+/|BEGIN (OPENSSH|RSA|EC|DSA) PRIVATE KEY|gh[opsu]_[[:alnum:]_]+)' \
    --exclude-dir=.git --exclude='*.png' .; then
    printf 'Potential private path, key, or token found\n' >&2
    exit 1
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git diff --check
    git diff --cached --check
fi

printf 'Repository validation passed.\n'
