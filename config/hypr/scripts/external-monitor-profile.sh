#!/usr/bin/env bash
# Automatically prefer HDMI at 100 Hz and fall back to the laptop panel.
# Usage: external-monitor-profile.sh [auto|external|internal]
set -u

external="HDMI-A-1"
internal="eDP-1"
config="${HOME}/.config/hypr/monitors.conf"
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

hyprctl_cmd=(hyprctl)
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl_cmd+=( -i "$HYPRLAND_INSTANCE_SIGNATURE" )
fi

write_profile() {
    local profile="$1" temp
    temp="$(mktemp "${config}.XXXXXX")"

    if [[ "$profile" == external ]]; then
        printf '%s\n' \
            '# Managed by external-monitor-profile.sh.' \
            'monitor=,preferred,auto,1' \
            'monitor=eDP-1,disable' \
            'monitor=HDMI-A-1,1920x1080@100.0,0x0,1.0' >"$temp"
        "${hyprctl_cmd[@]}" keyword monitor "$external,1920x1080@100,0x0,1" >/dev/null
        "${hyprctl_cmd[@]}" keyword monitor "$internal,disable" >/dev/null
    elif [[ "$profile" == internal ]]; then
        printf '%s\n' \
            '# Managed by external-monitor-profile.sh.' \
            'monitor=,preferred,auto,1' \
            'monitor=eDP-1,preferred,0x0,1' \
            'monitor=HDMI-A-1,disable' >"$temp"
        "${hyprctl_cmd[@]}" keyword monitor "$internal,preferred,0x0,1" >/dev/null
        "${hyprctl_cmd[@]}" keyword monitor "$external,disable" >/dev/null 2>&1 || true
    else
        printf '%s\n' \
            '# Managed by external-monitor-profile.sh.' \
            'monitor=,preferred,auto,1' >"$temp"
        "${hyprctl_cmd[@]}" keyword monitor ',preferred,auto,1' >/dev/null
    fi

    if ! cmp -s "$temp" "$config"; then
        mv "$temp" "$config"
    else
        rm -f "$temp"
    fi
}

detect_and_apply() {
    local monitors
    monitors="$("${hyprctl_cmd[@]}" -j monitors all 2>/dev/null || true)"
    if jq -e --arg output "$external" '.[] | select(.name == $output)' \
        >/dev/null 2>&1 <<<"$monitors"; then
        write_profile external
    elif jq -e --arg output "$internal" '.[] | select(.name == $output)' \
        >/dev/null 2>&1 <<<"$monitors"; then
        write_profile internal
    else
        write_profile generic
    fi
}

case "${1:-auto}" in
    external|internal|generic)
        write_profile "$1"
        exit 0
        ;;
    auto) ;;
    *)
        printf 'Usage: %s [auto|external|internal|generic]\n' "$0" >&2
        exit 2
        ;;
esac

# Only one hot-plug watcher is needed per user session.
exec 9>"${runtime_dir}/hypr-monitor-profile.lock"
flock -n 9 || exit 0

detect_and_apply

socket="${runtime_dir}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"
[[ -S "$socket" ]] || exit 0

python3 - "$socket" <<'PY' | while IFS= read -r event; do
import socket
import sys

connection = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
connection.connect(sys.argv[1])
with connection.makefile("r", encoding="utf-8", errors="replace") as events:
    for event in events:
        print(event, end="", flush=True)
PY
    case "$event" in
        monitoradded\>\>*|monitorremoved\>\>*|monitoraddedv2\>\>*|monitorremovedv2\>\>*)
            sleep 1
            detect_and_apply
            ;;
    esac
done
