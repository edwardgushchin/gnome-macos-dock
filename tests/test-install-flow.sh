#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/gnome-macos-dock-flow.XXXXXX")
trap 'rm -rf -- "$TEST_ROOT"' EXIT

MOCK_BIN="$TEST_ROOT/bin"
MOCK_LOG="$TEST_ROOT/mock.log"
TEST_HOME="$TEST_ROOT/home"
TEST_DATA="$TEST_HOME/.local/share"
TEST_STATE="$TEST_HOME/.local/state"
TEST_CACHE="$TEST_HOME/.cache"
EXTENSION_ROOT="$TEST_DATA/gnome-shell/extensions"

install -d -m 0700 "$MOCK_BIN" "$EXTENSION_ROOT"
: > "$MOCK_LOG"

cat > "$MOCK_BIN/gnome-shell" <<'EOF'
#!/usr/bin/env bash
printf 'GNOME Shell 50.4\n'
EOF

cat > "$MOCK_BIN/gnome-extensions" <<'EOF'
#!/usr/bin/env bash
printf 'gnome-extensions %s\n' "$*" >> "$MOCK_LOG"
exit 0
EOF

cat > "$MOCK_BIN/dconf" <<'EOF'
#!/usr/bin/env bash
printf 'dconf %s\n' "$*" >> "$MOCK_LOG"
case "${1:-}" in
    dump)
        printf '[/]\nmock=true\n'
        ;;
    load)
        cat >/dev/null
        ;;
esac
EOF

cat > "$MOCK_BIN/gsettings" <<'EOF'
#!/usr/bin/env bash
printf 'gsettings %s\n' "$*" >> "$MOCK_LOG"

if [[ "${1:-}" == --schemadir ]]; then
    shift 2
fi

if [[ "${1:-}" == get ]]; then
    case "${2:-} ${3:-}" in
        "org.gnome.shell enabled-extensions")
            printf "['existing@example.test']\n"
            ;;
        "org.gnome.shell favorite-apps")
            printf "['old.desktop']\n"
            ;;
        "org.gnome.desktop.interface icon-theme")
            printf "'OldIcons'\n"
            ;;
        "org.gnome.mutter dynamic-workspaces")
            printf "true\n"
            ;;
        "org.gnome.desktop.wm.preferences num-workspaces")
            printf "4\n"
            ;;
        *)
            printf "false\n"
            ;;
    esac
fi
EOF

chmod 0755 "$MOCK_BIN"/*

source "$ROOT_DIR/config/versions.env"
extension_uuids=(
    "$DASH_UUID"
    "$BLUR_UUID"
    "$FLOURISH_UUID"
    "$JUST_PERFECTION_UUID"
)

for uuid in "${extension_uuids[@]}"; do
    install -d -m 0700 "$EXTENSION_ROOT/$uuid"
    printf 'original fixture\n' > "$EXTENSION_ROOT/$uuid/original.txt"
done

export HOME="$TEST_HOME"
export XDG_DATA_HOME="$TEST_DATA"
export XDG_STATE_HOME="$TEST_STATE"
export XDG_CACHE_HOME="$TEST_CACHE"
export MOCK_LOG
export PATH="$MOCK_BIN:$PATH"

"$ROOT_DIR/install.sh" --yes --skip-icons --keep-favorites \
    > "$TEST_ROOT/install.log"

for uuid in "${extension_uuids[@]}"; do
    [[ -f "$EXTENSION_ROOT/$uuid/metadata.json" ]] ||
        { printf 'Extension was not installed: %s\n' "$uuid" >&2; exit 1; }
    [[ ! -f "$EXTENSION_ROOT/$uuid/original.txt" ]] ||
        { printf 'Old extension tree survived replacement: %s\n' "$uuid" >&2; exit 1; }
done

grep -q 'Keep pinned applications on the main monitor only' \
    "$EXTENSION_ROOT/$DASH_UUID/dash.js"
grep -q 'DASH_READY_RETRY_LIMIT' \
    "$EXTENSION_ROOT/$BLUR_UUID/components/dash_to_dock.js"

BACKUP_DIR=$(find "$TEST_STATE/gnome-macos-dock/backups" \
    -mindepth 1 -maxdepth 1 -type d -print -quit)
[[ -n "$BACKUP_DIR" && -f "$BACKUP_DIR/extensions.tar.gz" ]] ||
    { printf 'Installer backup is incomplete\n' >&2; exit 1; }

"$ROOT_DIR/restore.sh" --yes "$BACKUP_DIR" > "$TEST_ROOT/restore.log"

for uuid in "${extension_uuids[@]}"; do
    [[ -f "$EXTENSION_ROOT/$uuid/original.txt" ]] ||
        { printf 'Extension was not restored: %s\n' "$uuid" >&2; exit 1; }
    [[ ! -f "$EXTENSION_ROOT/$uuid/metadata.json" ]] ||
        { printf 'Installed extension survived restore: %s\n' "$uuid" >&2; exit 1; }
done

grep -q 'dconf load /org/gnome/shell/extensions/dash-to-dock/' "$MOCK_LOG"
grep -q 'gsettings set org.gnome.shell enabled-extensions' "$MOCK_LOG"

printf 'Isolated install and restore flow passed.\n'
