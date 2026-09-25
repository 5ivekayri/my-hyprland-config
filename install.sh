#!/usr/bin/env bash

set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
skip_packages=false

if [[ "$EUID" -eq 0 ]]; then
    printf 'Do not run this installer as root. Run it as your normal desktop user; sudo will be requested when needed.\n' >&2
    exit 1
fi

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

    package_available() {
        local package="$1"
        rpm -q "$package" >/dev/null 2>&1 ||
            [[ -n "$(dnf -q repoquery --available --qf '%{name}' "$package" 2>/dev/null)" ]]
    }

    enable_copr_for_package() {
        local package="$1"
        local copr="$2"
        local include_only="${3:-}"
        local repo_file

        if package_available "$package"; then
            return
        fi

        printf 'Enabling COPR %s for %s...\n' "$copr" "$package"
        sudo dnf copr enable -y "$copr"

        if [[ -n "$include_only" ]]; then
            repo_file="/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:${copr//\//:}.repo"
            if [[ -f "$repo_file" ]] && ! grep -qFx "includepkgs=$include_only" "$repo_file"; then
                printf 'includepkgs=%s\n' "$include_only" | sudo tee -a "$repo_file" >/dev/null
            fi
        fi
    }

    printf 'Checking package sources (based on JaKooLit/Fedora-Hyprland)...\n'
    sudo -v
    sudo dnf install -y dnf5-plugins
    enable_copr_for_package hyprland sdegler/hyprland
    enable_copr_for_package wallust errornointernet/packages wallust

    local required=(
        hyprland hyprpaper hyprlock hypridle hyprsunset
        waybar wofi rofi kitty thunar wlogout SwayNotificationCenter
        grim slurp swappy wl-clipboard cliphist playerctl brightnessctl
        pavucontrol jq bc ImageMagick ffmpeg-free cava wallust curl
        NetworkManager NetworkManager-wifi bluez bluez-tools
        pipewire pipewire-pulseaudio wireplumber
        xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        xdg-user-dirs xdg-utils
        mate-polkit libnotify util-linux procps-ng python3
        papirus-icon-theme adw-gtk3-theme bibata-cursor-theme
        jetbrains-mono-fonts jetbrainsmono-nerd-fonts
        nerdfontssymbolsonly-nerd-fonts fira-code-fonts fontawesome-fonts-all
        google-noto-sans-fonts google-noto-color-emoji-fonts
        nwg-look qt5ct qt6ct
        pamixer libcanberra-gtk3
    )
    local optional=()

    printf 'Installing required Fedora/Nobara packages...\n'
    sudo dnf install -y "${required[@]}"

    if ((${#optional[@]})); then
        printf 'Trying optional integration packages...\n'
        for package in "${optional[@]}"; do
            sudo dnf install -y "$package" || printf 'Optional package unavailable: %s\n' "$package"
        done
    fi

    sudo systemctl enable --now NetworkManager
    sudo systemctl enable --now bluetooth || true
}

if [[ "$skip_packages" == false ]]; then
    install_packages
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="$HOME/.config-backups/my-hyprland-config-$timestamp"
mkdir -p "$backup_dir" "$HOME/.config" "$HOME/.wallpapers" "$HOME/Pictures/screenshots"

if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    xdg-user-dirs-update
fi

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

pictures_dir="$(xdg-user-dir PICTURES 2>/dev/null || printf '%s' "$HOME/Pictures")"
mkdir -p "$pictures_dir/screenshots" "$pictures_dir/wallpapers"
cp -a "$repo_dir/wallpapers/thunderstorm-sea.webp" "$pictures_dir/wallpapers/"

find "$HOME/.config/hypr/scripts" "$HOME/.config/hypr/UserScripts" \
    -type f -name '*.sh' -exec chmod u+x {} + 2>/dev/null || true

if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || true
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' || true
    gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' || true
    gsettings set org.gnome.desktop.interface cursor-size 24 || true
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
printf 'Reboot, choose the Hyprland session on the login screen, and sign in.\n'
printf 'Review monitor names in ~/.config/hypr/monitors.conf if they differ from eDP-1 and HDMI-A-1.\n'
