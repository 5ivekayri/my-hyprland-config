#!/usr/bin/env bash

set -u

pictures_dir="$(xdg-user-dir PICTURES 2>/dev/null || printf '%s' "$HOME/Изображения")"
wall_dir="$pictures_dir/wallpapers"
hyprpaper_config="$HOME/.config/hypr/hyprpaper.conf"

selected="$({
  find "$wall_dir" "$HOME/.wallpapers" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    2>/dev/null | sort
} | rofi -dmenu -i -p 'Wallpaper')"

[[ -n "$selected" ]] || exit 0

extension="${selected##*.}"
installed="$HOME/.wallpapers/selected-wallpaper.$extension"
cp -- "$selected" "$installed"

sed -i "s|^[[:space:]]*path = .*|    path = $installed|" "$hyprpaper_config"

pkill hyprpaper 2>/dev/null || true
hyprpaper >/dev/null 2>&1 &
