#!/usr/bin/env bash

set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
skip_packages=false

if [[ "${1:-}" == "--skip-packages" ]]; then
    skip_packages=true
elif [[ -n "${1:-}" ]]; then
    printf 'Usage: %s [--skip-packages]\n' "$0" >&2
    exit 2
fi

if [[ ! -d "$repo_dir/config/hypr" || ! -f "$repo_dir/wallpapers/thunderstorm-sea.webp" ]]; then
    printf 'Error: run this script from a complete repository clone.\n' >&2
    exit 1
fi

install_packages() {
    if ! command -v dnf >/dev/null 2>&1; then
        printf 'Skipping packages: this automatic installer currently supports Fedora/Nobara.\n'
        return
    fi

    local required=(
        hyprland hyprpaper waybar wofi kitty thunar rofi
        wlogout swaynotificationcenter grim slurp swappy wl-clipboard playerctl
        brightnessctl pavucontrol jq bc ImageMagick ffmpeg
        NetworkManager python3 papirus-icon-theme adw-gtk3-theme
    )
    local optional=(wallust cliphist hyprlock hypridle hyprsunset cava)

    printf 'Installing required Fedora/Nobara packages...\n'
    sudo dnf install -y "${required[@]}"

    printf 'Trying optional integration packages...\n'
    for package in "${optional[@]}"; do
        sudo dnf install -y "$package" || printf 'Optional package unavailable: %s\n' "$package"
    done
}

if [[ "$skip_packages" == false ]]; then
    install_packages
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="$HOME/.config-backups/my-hyprland-config-$timestamp"
mkdir -p "$backup_dir" "$HOME/.config" "$HOME/.wallpapers"

targets=(
    hypr waybar wofi kitty rofi wlogout swaync swappy wallust gtk-3.0 gtk-4.0
)

printf 'Backing up current configuration to %s\n' "$backup_dir"
for target in "${targets[@]}"; do
    if [[ -e "$HOME/.config/$target" ]]; then
        mv "$HOME/.config/$target" "$backup_dir/$target"
    fi
done

if [[ -e "$HOME/.wallpapers/thunderstorm-sea.webp" ]]; then
    mkdir -p "$backup_dir/wallpapers"
    mv "$HOME/.wallpapers/thunderstorm-sea.webp" "$backup_dir/wallpapers/"
fi

cp -a "$repo_dir/config/." "$HOME/.config/"
cp -a "$repo_dir/wallpapers/thunderstorm-sea.webp" "$HOME/.wallpapers/"
ln -sfn "$HOME/.wallpapers/thunderstorm-sea.webp" "$HOME/.config/rofi/.current_wallpaper"

find "$HOME/.config/hypr/scripts" "$HOME/.config/hypr/UserScripts" \
    -type f -name '*.sh' -exec chmod u+x {} + 2>/dev/null || true

if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || true
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' || true
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
    gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' || true
fi

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
    hyprctl reload || true
    hyprctl dispatch exec 'pkill hyprpaper; hyprpaper' || true
    hyprctl dispatch exec 'pkill waybar; waybar' || true
fi

printf '\nInstallation complete.\n'
printf 'Backup: %s\n' "$backup_dir"
printf 'If the session was not active, log out and back in to apply everything.\n'
printf 'Review monitor names in ~/.config/hypr/monitors.conf if they differ from eDP-1 and HDMI-A-1.\n'
