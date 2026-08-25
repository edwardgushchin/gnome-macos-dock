#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=config/versions.env
source "$ROOT_DIR/config/versions.env"
# shellcheck source=scripts/lib.sh
source "$ROOT_DIR/scripts/lib.sh"

DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
EXTENSION_ROOT="$DATA_HOME/gnome-shell/extensions"
failures=0

pass() {
    printf '\033[1;32mPASS\033[0m  %s\n' "$*"
}

fail() {
    printf '\033[1;31mFAIL\033[0m  %s\n' "$*"
    failures=$((failures + 1))
}

check_extension() {
    local uuid=$1
    local expected_version=$2
    local metadata="$EXTENSION_ROOT/$uuid/metadata.json"
    local state

    if [[ ! -f "$metadata" ]]; then
        fail "$uuid is not installed"
        return
    fi
    if grep -Fq "\"version-name\": \"$expected_version\"" "$metadata" ||
        grep -Eq "\"version\"[[:space:]]*:[[:space:]]*$expected_version([,[:space:]]|$)" "$metadata"; then
        pass "$uuid version $expected_version is installed"
    else
        fail "$uuid does not match version $expected_version"
    fi

    state=$(gnome-extensions info "$uuid" 2>/dev/null |
        awk -F': ' '/State:/{print $2; exit}')
    if [[ "$state" == ACTIVE ]]; then
        pass "$uuid is ACTIVE"
    else
        fail "$uuid state is ${state:-unknown}; sign out and back in"
    fi
}

check_gsetting() {
    local schema_dir=$1
    local schema=$2
    local key=$3
    local expected=$4
    local actual

    actual=$(gsettings --schemadir "$schema_dir" get "$schema" "$key" 2>/dev/null) || {
        fail "$schema $key is unavailable"
        return
    }
    if [[ "$actual" == "$expected" ]]; then
        pass "$key = $actual"
    else
        fail "$key expected $expected, got $actual"
    fi
}

check_extension "$DASH_UUID" "$DASH_VERSION"
check_extension "$BLUR_UUID" "$BLUR_VERSION"
check_extension "$FLOURISH_UUID" "$FLOURISH_VERSION"
check_extension "$JUST_PERFECTION_UUID" "$JUST_PERFECTION_VERSION"

if grep -q 'Keep pinned applications on the main monitor only' \
    "$EXTENSION_ROOT/$DASH_UUID/dash.js" 2>/dev/null; then
    pass "Dash to Dock per-monitor patch is present"
else
    fail "Dash to Dock per-monitor patch is missing"
fi

if grep -q 'DASH_READY_RETRY_LIMIT' \
    "$EXTENSION_ROOT/$BLUR_UUID/components/dash_to_dock.js" 2>/dev/null; then
    pass "Blur My Shell startup-race patch is present"
else
    fail "Blur My Shell startup-race patch is missing"
fi

dash_schema="$EXTENSION_ROOT/$DASH_UUID/schemas"
blur_schema="$EXTENSION_ROOT/$BLUR_UUID/schemas"
flourish_schema="$EXTENSION_ROOT/$FLOURISH_UUID/schemas"

check_gsetting "$dash_schema" org.gnome.shell.extensions.dash-to-dock \
    background-color "'#202020'"
check_gsetting "$dash_schema" org.gnome.shell.extensions.dash-to-dock \
    background-opacity '0.23999999999999999'
check_gsetting "$dash_schema" org.gnome.shell.extensions.dash-to-dock \
    dash-max-icon-size '40'
check_gsetting "$dash_schema" org.gnome.shell.extensions.dash-to-dock \
    multi-monitor 'true'
check_gsetting "$dash_schema" org.gnome.shell.extensions.dash-to-dock \
    isolate-monitors 'true'
check_gsetting "$blur_schema" org.gnome.shell.extensions.blur-my-shell.dash-to-dock \
    blur 'true'
check_gsetting "$blur_schema" org.gnome.shell.extensions.blur-my-shell.dash-to-dock \
    sigma '30'
check_gsetting "$flourish_schema" org.gnome.shell.extensions.flourish \
    motion-profile "'custom'"
check_gsetting "$flourish_schema" org.gnome.shell.extensions.flourish \
    custom-launch-repeat 'false'

active_icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || true)
if [[ "$active_icon_theme" == "'$WHITESUR_ACTIVE_THEME'" ]]; then
    pass "WhiteSur-dark is active"
else
    fail "Active icon theme is ${active_icon_theme:-unknown}"
fi

for icon_name in codex-desktop express vk-messenger; do
    expected=$(awk -v file="apps/$icon_name.svg" '$2 == file {print $1}' \
        "$ROOT_DIR/icons/SHA256SUMS")
    installed="$DATA_HOME/icons/WhiteSur-dark/apps/scalable/$icon_name.svg"
    if [[ -f "$installed" ]] &&
        [[ "$(sha256sum "$installed" | awk '{print $1}')" == "$expected" ]]; then
        pass "$icon_name.svg is installed and verified"
    else
        fail "$icon_name.svg is missing or modified"
    fi
done

if ((failures)); then
    printf '\n%d check(s) failed.\n' "$failures"
    exit 1
fi

printf '\n'
success "The installed desktop matches gnome-macos-dock $PROJECT_VERSION"
