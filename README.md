# My Hyprland configuration

My current Hyprland desktop for Fedora/Nobara: a dark stormy-ocean palette,
transparent Waybar, Wofi application search, US/RU keyboard layouts, a compact
GTK theme, wallpaper picker, notification center, power menu, screenshots and
laptop/media controls.

![Wallpaper](wallpapers/thunderstorm-sea.webp)

## Quick install

> The installer replaces the listed configuration directories, but first moves
> the existing versions to a timestamped directory under `~/.config-backups/`.

```bash
git clone https://github.com/5ivekayri/my-hyprland-config.git
cd my-hyprland-config
chmod +x install.sh
./install.sh
```

If all dependencies are already installed:

```bash
./install.sh --skip-packages
```

The automatic package step targets Fedora and Nobara. On other distributions,
use `--skip-packages` and install equivalent packages manually.

## Important shortcuts

| Shortcut | Action |
| --- | --- |
| `Super+D` | Application search |
| `Super+Enter` | Kitty terminal |
| `Super+E` | Thunar file manager |
| `Super+W` | Wallpaper picker |
| `Super+Q` | Close active window |
| `Super+Space` | Toggle floating |
| `Super+1…0` | Switch workspace |
| `Super+Shift+1…0` | Move window to workspace |
| `Super+Shift+S` | Area screenshot through Swappy |
| `Ctrl+Alt+L` | Lock screen |
| `Ctrl+Alt+P` | Power menu |
| `Ctrl+Alt+Delete` | Exit Hyprland |
| `Alt+Shift` | Switch US/RU layout |

## Monitor setup

The checked-in profile matches the source laptop:

- internal display: `eDP-1`, 125% scale;
- external display: `HDMI-A-1`, 1920×1080 at 100 Hz;
- connecting HDMI automatically switches to the external display.

If your output names differ, edit:

- `~/.config/hypr/monitors.conf`
- `~/.config/hypr/scripts/external-monitor-profile.sh`
- monitor blocks in `~/.config/hypr/hyprpaper.conf`

Use `hyprctl monitors all` to find the correct names.

## Included configuration

- Hyprland and hyprpaper
- Waybar and hotspot helper
- Wofi and Rofi menus
- Kitty
- Wlogout
- SwayNC
- Swappy
- Wallust templates
- GTK 3/4 preferences
- `thunderstorm-sea` wallpaper

## Credits

This setup grew from and combines ideas and scripts from:

- [maxhu08/dotfiles](https://github.com/maxhu08/dotfiles)
- [maxhu08/dotfiles-old](https://github.com/maxhu08/dotfiles-old)
- [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots)

Review upstream licenses when redistributing individual borrowed assets or
scripts.
