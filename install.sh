#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=config/versions.env
source "$ROOT_DIR/config/versions.env"
# shellcheck source=scripts/lib.sh
source "$ROOT_DIR/scripts/lib.sh"

ASSUME_YES=false
DRY_RUN=false
FORCE_GNOME_VERSION=false
KEEP_FAVORITES=false
SKIP_ICONS=false
MAIN_MONITOR=''

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Installs the pinned GNOME dock preset, extensions, patches, and WhiteSur icons.

Options:
  --yes                    Do not ask for confirmation.
  --dry-run                Verify downloads, checksums, and patches only.
  --force-gnome-version    Continue outside the tested GNOME version range.
  --keep-favorites         Preserve the current favorite applications.
  --skip-icons             Do not install or activate WhiteSur icons.
  --main-monitor NAME      Pin the main dock to a connector such as DP-3.
  -h, --help               Show this help.
EOF
}

while (($#)); do
    case "$1" in
        --yes)
            ASSUME_YES=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --force-gnome-version)
            FORCE_GNOME_VERSION=true
            ;;
        --keep-favorites)
            KEEP_FAVORITES=true
            ;;
        --skip-icons)
            SKIP_ICONS=true
            ;;
        --main-monitor)
            (($# >= 2)) || die "--main-monitor requires a connector name"
            MAIN_MONITOR=$2
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown option: $1"
            ;;
    esac
    shift
done

for command_name in awk bsdtar curl git glib-compile-schemas patch sha256sum; do
    require_command "$command_name"
done

DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
CACHE_HOME=${XDG_CACHE_HOME:-"$HOME/.cache"}
EXTENSION_ROOT="$DATA_HOME/gnome-shell/extensions"
ICON_ROOT="$DATA_HOME/icons"
CACHE_DIR="$CACHE_HOME/gnome-macos-dock/downloads"
STATE_ROOT="$STATE_HOME/gnome-macos-dock"

EXTENSION_UUIDS=(
    "$DASH_UUID"
    "$BLUR_UUID"
    "$FLOURISH_UUID"
    "$JUST_PERFECTION_UUID"
)

verify_custom_icons() {
    (
        cd "$ROOT_DIR/icons"
        sha256sum --check SHA256SUMS
    )
}

stage_and_patch_extension() {
    local archive=$1
    local uuid=$2
    local patch_file=${3:-}
    local stage_root=$4
    local destination="$stage_root/$uuid"

    install -d -m 0700 "$destination"
    bsdtar -xf "$archive" -C "$destination"

    if [[ -n "$patch_file" ]]; then
        patch --batch --forward --strip=1 --directory="$destination" < "$patch_file"
    fi

    if [[ -d "$destination/schemas" ]]; then
        glib-compile-schemas --strict "$destination/schemas"
    fi
}

verify_sources() {
    local verify_root
    verify_root=$(mktemp -d "${TMPDIR:-/tmp}/gnome-macos-dock-verify.XXXXXX")
    trap 'rm -rf -- "$verify_root"' RETURN

    log "Verifying pinned extension archives"
    download_verified "$DASH_URL" "$DASH_SHA256" "$verify_root/dash.zip"
    download_verified "$BLUR_URL" "$BLUR_SHA256" "$verify_root/blur.zip"
    download_verified "$FLOURISH_URL" "$FLOURISH_SHA256" "$verify_root/flourish.zip"
    download_verified "$JUST_PERFECTION_URL" "$JUST_PERFECTION_SHA256" "$verify_root/just-perfection.zip"

    stage_and_patch_extension \
        "$verify_root/dash.zip" "$DASH_UUID" \
        "$ROOT_DIR/patches/dash-to-dock-v105.patch" "$verify_root/stage"
    stage_and_patch_extension \
        "$verify_root/blur.zip" "$BLUR_UUID" \
        "$ROOT_DIR/patches/blur-my-shell-v72.patch" "$verify_root/stage"
    stage_and_patch_extension \
        "$verify_root/flourish.zip" "$FLOURISH_UUID" '' "$verify_root/stage"
    stage_and_patch_extension \
        "$verify_root/just-perfection.zip" "$JUST_PERFECTION_UUID" '' "$verify_root/stage"

    verify_custom_icons
    git ls-remote --exit-code "$WHITESUR_REPOSITORY" >/dev/null
    success "All pinned sources, patches, and custom icons are valid"
}

if [[ "$DRY_RUN" == true ]]; then
    verify_sources
    exit 0
fi

for command_name in \
    dconf gnome-extensions gnome-shell gsettings python3 tar; do
    require_command "$command_name"
done

GNOME_MAJOR=$(gnome-shell --version | awk '{print $3}' | cut -d. -f1)
[[ "$GNOME_MAJOR" =~ ^[0-9]+$ ]] || die "Unable to determine the GNOME Shell version"
if ((GNOME_MAJOR < GNOME_MIN_MAJOR || GNOME_MAJOR > GNOME_MAX_MAJOR)); then
    if [[ "$FORCE_GNOME_VERSION" != true ]]; then
        die "GNOME $GNOME_MAJOR is outside the tested range $GNOME_MIN_MAJOR-$GNOME_MAX_MAJOR"
    fi
    warn "Continuing on untested GNOME $GNOME_MAJOR"
fi

if [[ "$ASSUME_YES" != true ]]; then
    cat <<EOF
This will replace four user GNOME extensions, apply the dock preset, and
$([[ "$SKIP_ICONS" == true ]] && printf 'leave the icon theme unchanged.' || printf 'install WhiteSur and activate WhiteSur-dark.')

A timestamped backup will be created under:
  $STATE_ROOT/backups
EOF
    read -r -p "Continue? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || die "Cancelled"
fi

timestamp=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$STATE_ROOT/backups/$timestamp"
STAGE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/gnome-macos-dock-install.XXXXXX")
BACKUP_READY=false

cleanup() {
    rm -rf -- "$STAGE_DIR"
}

rollback_on_error() {
    local status=$?
    trap - ERR
    warn "Installation failed"
    if [[ "$BACKUP_READY" == true ]]; then
        warn "Restoring the backup created at $BACKUP_DIR"
        "$ROOT_DIR/restore.sh" --yes "$BACKUP_DIR" ||
            warn "Automatic restore failed; the backup remains available"
    fi
    exit "$status"
}

trap cleanup EXIT
trap rollback_on_error ERR

backup_current_state() {
    local uuid
    local launcher
    local theme_dir
    local extension_names=()
    local theme_names=()

    log "Creating backup at $BACKUP_DIR"
    install -d -m 0700 \
        "$BACKUP_DIR/dconf" \
        "$BACKUP_DIR/gsettings" \
        "$BACKUP_DIR/launchers"

    dconf dump /org/gnome/shell/extensions/dash-to-dock/ \
        > "$BACKUP_DIR/dconf/dash-to-dock.ini"
    dconf dump /org/gnome/shell/extensions/blur-my-shell/ \
        > "$BACKUP_DIR/dconf/blur-my-shell.ini"
    dconf dump /org/gnome/shell/extensions/flourish/ \
        > "$BACKUP_DIR/dconf/flourish.ini"
    dconf dump /org/gnome/shell/extensions/just-perfection/ \
        > "$BACKUP_DIR/dconf/just-perfection.ini"

    gsettings get org.gnome.shell enabled-extensions \
        > "$BACKUP_DIR/gsettings/enabled-extensions.gvariant"
    gsettings get org.gnome.shell favorite-apps \
        > "$BACKUP_DIR/gsettings/favorite-apps.gvariant"
    gsettings get org.gnome.desktop.interface icon-theme \
        > "$BACKUP_DIR/gsettings/icon-theme.gvariant"
    gsettings get org.gnome.mutter dynamic-workspaces \
        > "$BACKUP_DIR/gsettings/dynamic-workspaces.gvariant"
    gsettings get org.gnome.desktop.wm.preferences num-workspaces \
        > "$BACKUP_DIR/gsettings/num-workspaces.gvariant"

    : > "$BACKUP_DIR/extensions-present.txt"
    for uuid in "${EXTENSION_UUIDS[@]}"; do
        if [[ -d "$EXTENSION_ROOT/$uuid" ]]; then
            extension_names+=("$uuid")
            printf '%s\n' "$uuid" >> "$BACKUP_DIR/extensions-present.txt"
        fi
    done
    if ((${#extension_names[@]})); then
        tar -C "$EXTENSION_ROOT" -czf "$BACKUP_DIR/extensions.tar.gz" \
            "${extension_names[@]}"
    fi

    : > "$BACKUP_DIR/whitesur-present.txt"
    if [[ -d "$ICON_ROOT" ]]; then
        while IFS= read -r -d '' theme_dir; do
            theme_names+=("$(basename "$theme_dir")")
            printf '%s\n' "$(basename "$theme_dir")" \
                >> "$BACKUP_DIR/whitesur-present.txt"
        done < <(find "$ICON_ROOT" -mindepth 1 -maxdepth 1 -type d \
            -name 'WhiteSur*' -print0)
    fi
    if ((${#theme_names[@]})); then
        tar -C "$ICON_ROOT" -czf "$BACKUP_DIR/whitesur-icons.tar.gz" \
            "${theme_names[@]}"
    fi

    for launcher in vk-messenger.desktop express.desktop thunderbird-nightly.desktop; do
        if [[ -f "$DATA_HOME/applications/$launcher" ]]; then
            cp -a -- "$DATA_HOME/applications/$launcher" \
                "$BACKUP_DIR/launchers/$launcher"
        fi
    done

    printf '%s\n' "$PROJECT_VERSION" > "$BACKUP_DIR/project-version"
    chmod -R go-rwx "$BACKUP_DIR"
    BACKUP_READY=true
}

install_extension_tree() {
    local staged=$1
    local uuid=$2
    local target="$EXTENSION_ROOT/$uuid"

    validate_extension_target "$EXTENSION_ROOT" "$target"
    rm -rf -- "$target"
    install -d -m 0700 "$EXTENSION_ROOT"
    cp -a -- "$staged/$uuid" "$target"
}

install_extensions() {
    local uuid

    log "Downloading and verifying pinned extensions"
    download_verified "$DASH_URL" "$DASH_SHA256" "$CACHE_DIR/dash-to-dock-v105.zip"
    download_verified "$BLUR_URL" "$BLUR_SHA256" "$CACHE_DIR/blur-my-shell-v72.zip"
    download_verified "$FLOURISH_URL" "$FLOURISH_SHA256" "$CACHE_DIR/flourish-v1.0.0.zip"
    download_verified "$JUST_PERFECTION_URL" "$JUST_PERFECTION_SHA256" \
        "$CACHE_DIR/just-perfection-v36.zip"

    for uuid in "${EXTENSION_UUIDS[@]}"; do
        gnome-extensions disable "$uuid" >/dev/null 2>&1 || true
    done

    stage_and_patch_extension \
        "$CACHE_DIR/dash-to-dock-v105.zip" "$DASH_UUID" \
        "$ROOT_DIR/patches/dash-to-dock-v105.patch" "$STAGE_DIR/extensions"
    stage_and_patch_extension \
        "$CACHE_DIR/blur-my-shell-v72.zip" "$BLUR_UUID" \
        "$ROOT_DIR/patches/blur-my-shell-v72.patch" "$STAGE_DIR/extensions"
    stage_and_patch_extension \
        "$CACHE_DIR/flourish-v1.0.0.zip" "$FLOURISH_UUID" '' "$STAGE_DIR/extensions"
    stage_and_patch_extension \
        "$CACHE_DIR/just-perfection-v36.zip" "$JUST_PERFECTION_UUID" '' \
        "$STAGE_DIR/extensions"

    for uuid in "${EXTENSION_UUIDS[@]}"; do
        install_extension_tree "$STAGE_DIR/extensions" "$uuid"
    done
}

install_whitesur() {
    local source_dir="$STAGE_DIR/WhiteSur-icon-theme"
    local icon_file

    [[ "$SKIP_ICONS" == true ]] && return 0

    log "Installing the pinned WhiteSur icon theme and custom application icons"
    git init -q "$source_dir"
    git -C "$source_dir" remote add origin "$WHITESUR_REPOSITORY"
    git -C "$source_dir" fetch -q --depth=1 origin "$WHITESUR_COMMIT"
    [[ "$(git -C "$source_dir" rev-parse FETCH_HEAD)" == "$WHITESUR_COMMIT" ]] ||
        die "WhiteSur commit verification failed"
    git -C "$source_dir" checkout -q --detach FETCH_HEAD

    verify_custom_icons
    for icon_file in "$ROOT_DIR"/icons/apps/*.svg; do
        install -m 0644 "$icon_file" "$source_dir/src/apps/scalable/"
    done

    (
        cd "$source_dir"
        ./install.sh
        ./install.sh -t pink
    )

    gsettings set org.gnome.desktop.interface icon-theme "$WHITESUR_ACTIVE_THEME"
}

set_launcher_icon() {
    local launcher=$1
    local icon_name=$2
    local file="$DATA_HOME/applications/$launcher"

    [[ -f "$file" ]] || {
        warn "Launcher not found, skipping icon mapping: $launcher"
        return 0
    }

    if grep -q '^Icon=' "$file"; then
        sed -i "s|^Icon=.*$|Icon=$icon_name|" "$file"
    else
        printf '\nIcon=%s\n' "$icon_name" >> "$file"
    fi
}

apply_settings() {
    local dash_schema_dir="$EXTENSION_ROOT/$DASH_UUID/schemas"
    local enabled_value

    log "Applying the reproducible GNOME settings"
    dconf reset -f /org/gnome/shell/extensions/dash-to-dock/
    dconf load /org/gnome/shell/extensions/dash-to-dock/ \
        < "$ROOT_DIR/config/dash-to-dock.ini"
    dconf reset -f /org/gnome/shell/extensions/blur-my-shell/dash-to-dock/
    dconf load /org/gnome/shell/extensions/blur-my-shell/dash-to-dock/ \
        < "$ROOT_DIR/config/blur-my-shell.ini"
    dconf reset -f /org/gnome/shell/extensions/flourish/
    dconf load /org/gnome/shell/extensions/flourish/ \
        < "$ROOT_DIR/config/flourish.ini"
    dconf load /org/gnome/shell/extensions/just-perfection/ \
        < "$ROOT_DIR/config/just-perfection.ini"

    if [[ -n "$MAIN_MONITOR" ]]; then
        gsettings --schemadir "$dash_schema_dir" set \
            org.gnome.shell.extensions.dash-to-dock \
            preferred-monitor-by-connector "$MAIN_MONITOR"
    else
        gsettings --schemadir "$dash_schema_dir" reset \
            org.gnome.shell.extensions.dash-to-dock \
            preferred-monitor-by-connector
    fi

    gsettings set org.gnome.mutter dynamic-workspaces false
    gsettings set org.gnome.desktop.wm.preferences num-workspaces 1
    if [[ "$KEEP_FAVORITES" != true ]]; then
        gsettings set org.gnome.shell favorite-apps \
            "$(read_gvariant_file "$ROOT_DIR/config/favorite-apps.gvariant")"
    fi

    enabled_value=$(python3 - \
        "$(gsettings get org.gnome.shell enabled-extensions)" \
        "${EXTENSION_UUIDS[@]}" <<'PY'
import ast
import sys

current = ast.literal_eval(sys.argv[1])
targets = sys.argv[2:]
ordered = targets + [item for item in current if item not in targets]
print(repr(ordered))
PY
)
    gsettings set org.gnome.shell enabled-extensions "$enabled_value"
}

backup_current_state
install_extensions
install_whitesur

if [[ "$SKIP_ICONS" != true ]]; then
    set_launcher_icon vk-messenger.desktop vk-messenger
    set_launcher_icon express.desktop express
    set_launcher_icon thunderbird-nightly.desktop thunderbird-nightly
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$DATA_HOME/applications" >/dev/null 2>&1 || true
    fi
fi

apply_settings

for uuid in "${EXTENSION_UUIDS[@]}"; do
    gnome-extensions enable "$uuid" >/dev/null 2>&1 ||
        warn "GNOME will enable $uuid after the next sign-in"
done

trap - ERR
success "GNOME macOS Dock $PROJECT_VERSION is installed"
printf '\nBackup: %s\n' "$BACKUP_DIR"
printf 'Log out and sign back in once, then run: %s/status.sh\n' "$ROOT_DIR"
