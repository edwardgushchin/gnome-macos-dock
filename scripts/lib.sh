#!/usr/bin/env bash

log() {
    printf '\033[1;34m==>\033[0m %s\n' "$*"
}

success() {
    printf '\033[1;32m==>\033[0m %s\n' "$*"
}

warn() {
    printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2
}

die() {
    printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command is missing: $1"
}

sha256_matches() {
    local file=$1
    local expected=$2
    local actual
    actual=$(sha256sum "$file" | awk '{print $1}')
    [[ "$actual" == "$expected" ]]
}

verify_sha256() {
    local file=$1
    local expected=$2
    local actual

    if ! sha256_matches "$file" "$expected"; then
        actual=$(sha256sum "$file" | awk '{print $1}')
        die "Checksum mismatch for $(basename "$file"): expected $expected, got $actual"
    fi
}

download_verified() {
    local url=$1
    local expected=$2
    local destination=$3

    if [[ -f "$destination" ]]; then
        if sha256_matches "$destination" "$expected"; then
            return 0
        fi
        warn "Discarding cached file with an invalid checksum: $destination"
        rm -f -- "$destination"
    fi

    install -d -m 0700 "$(dirname "$destination")"
    curl --fail --location --retry 3 --proto '=https' --tlsv1.2 \
        --output "${destination}.part" "$url"
    verify_sha256 "${destination}.part" "$expected"
    mv -- "${destination}.part" "$destination"
}

validate_extension_target() {
    local extension_root=$1
    local target=$2
    case "$target" in
        "$extension_root"/dash-to-dock@micxgx.gmail.com|\
        "$extension_root"/blur-my-shell@aunetx|\
        "$extension_root"/flourish@orsso.github.io|\
        "$extension_root"/just-perfection-desktop@just-perfection)
            ;;
        *)
            die "Refusing unsafe extension target: $target"
            ;;
    esac
}

read_gvariant_file() {
    local file=$1
    [[ -s "$file" ]] || die "Missing saved setting: $file"
    tr -d '\n' < "$file"
}
