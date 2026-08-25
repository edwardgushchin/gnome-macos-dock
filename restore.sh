#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=config/versions.env
source "$ROOT_DIR/config/versions.env"
# shellcheck source=scripts/lib.sh
source "$ROOT_DIR/scripts/lib.sh"

ASSUME_YES=false
BACKUP_ARGUMENT=''

usage() {
    cat <<'EOF'
Usage: ./restore.sh [--yes] [latest|BACKUP_DIRECTORY]

Restores extensions, dconf settings, WhiteSur directories, launchers, favorite
applications, workspaces, and the enabled-extension list from an installer
backup. The backup itself is retained.
EOF
}

while (($#)); do
    case "$1" in
        --yes)
            ASSUME_YES=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        latest)
            BACKUP_ARGUMENT=latest
            ;;
        -*)
            die "Unknown option: $1"
            ;;
        *)
            [[ -z "$BACKUP_ARGUMENT" ]] || die "Only one backup may be selected"
            BACKUP_ARGUMENT=$1
            ;;
    esac
    shift
done

for command_name in dconf gsettings tar; do
    require_command "$command_name"
done

DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
STATE_ROOT="$STATE_HOME/gnome-macos-dock"
EXTENSION_ROOT="$DATA_HOME/gnome-shell/extensions"
ICON_ROOT="$DATA_HOME/icons"

if [[ -z "$BACKUP_ARGUMENT" || "$BACKUP_ARGUMENT" == latest ]]; then
    [[ -d "$STATE_ROOT/backups" ]] || die "No installer backups found"
    BACKUP_DIR=$(find "$STATE_ROOT/backups" -mindepth 1 -maxdepth 1 -type d \
        -printf '%p\n' | sort | tail -n 1)
else
    BACKUP_DIR=$(realpath -e "$BACKUP_ARGUMENT")
fi

[[ -n "${BACKUP_DIR:-}" && -d "$BACKUP_DIR" ]] || die "Backup not found"
[[ -f "$BACKUP_DIR/project-version" ]] || die "Not a gnome-macos-dock backup: $BACKUP_DIR"

if [[ "$ASSUME_YES" != true ]]; then
    printf 'Restore this backup?\n  %s\n' "$BACKUP_DIR"
    read -r -p "Continue? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || die "Cancelled"
fi

EXTENSION_UUIDS=(
    "$DASH_UUID"
    "$BLUR_UUID"
    "$FLOURISH_UUID"
    "$JUST_PERFECTION_UUID"
)

remove_installed_extensions() {
    local uuid
    local target
    for uuid in "${EXTENSION_UUIDS[@]}"; do
        target="$EXTENSION_ROOT/$uuid"
        validate_extension_target "$EXTENSION_ROOT" "$target"
        rm -rf -- "$target"
    done
}

remove_whitesur_directories() {
    local theme_dir
    [[ -d "$ICON_ROOT" ]] || return 0
    while IFS= read -r -d '' theme_dir; do
        case "$(basename "$theme_dir")" in
            WhiteSur*) rm -rf -- "$theme_dir" ;;
            *) die "Refusing unsafe icon-theme target: $theme_dir" ;;
        esac
    done < <(find "$ICON_ROOT" -mindepth 1 -maxdepth 1 -type d \
        -name 'WhiteSur*' -print0)
}

restore_dconf_path() {
    local path=$1
    local file=$2
    dconf reset -f "$path"
    if [[ -s "$file" ]]; then
        dconf load "$path" < "$file"
    fi
}

log "Restoring extension files"
remove_installed_extensions
if [[ -f "$BACKUP_DIR/extensions.tar.gz" ]]; then
    install -d -m 0700 "$EXTENSION_ROOT"
    tar -C "$EXTENSION_ROOT" -xzf "$BACKUP_DIR/extensions.tar.gz"
fi

log "Restoring dconf and GNOME settings"
restore_dconf_path /org/gnome/shell/extensions/dash-to-dock/ \
    "$BACKUP_DIR/dconf/dash-to-dock.ini"
restore_dconf_path /org/gnome/shell/extensions/blur-my-shell/ \
    "$BACKUP_DIR/dconf/blur-my-shell.ini"
restore_dconf_path /org/gnome/shell/extensions/flourish/ \
    "$BACKUP_DIR/dconf/flourish.ini"
restore_dconf_path /org/gnome/shell/extensions/just-perfection/ \
    "$BACKUP_DIR/dconf/just-perfection.ini"

gsettings set org.gnome.shell favorite-apps \
    "$(read_gvariant_file "$BACKUP_DIR/gsettings/favorite-apps.gvariant")"
gsettings set org.gnome.desktop.interface icon-theme \
    "$(read_gvariant_file "$BACKUP_DIR/gsettings/icon-theme.gvariant")"
gsettings set org.gnome.mutter dynamic-workspaces \
    "$(read_gvariant_file "$BACKUP_DIR/gsettings/dynamic-workspaces.gvariant")"
gsettings set org.gnome.desktop.wm.preferences num-workspaces \
    "$(read_gvariant_file "$BACKUP_DIR/gsettings/num-workspaces.gvariant")"

log "Restoring WhiteSur and launcher files"
remove_whitesur_directories
if [[ -f "$BACKUP_DIR/whitesur-icons.tar.gz" ]]; then
    install -d -m 0700 "$ICON_ROOT"
    tar -C "$ICON_ROOT" -xzf "$BACKUP_DIR/whitesur-icons.tar.gz"
fi

if [[ -d "$BACKUP_DIR/launchers" ]]; then
    install -d -m 0700 "$DATA_HOME/applications"
    for launcher_file in "$BACKUP_DIR"/launchers/*.desktop; do
        [[ -e "$launcher_file" ]] || continue
        cp -a -- "$launcher_file" "$DATA_HOME/applications/"
    done
fi

gsettings set org.gnome.shell enabled-extensions \
    "$(read_gvariant_file "$BACKUP_DIR/gsettings/enabled-extensions.gvariant")"

success "Backup restored: $BACKUP_DIR"
printf 'Log out and sign back in once to reload GNOME Shell.\n'
