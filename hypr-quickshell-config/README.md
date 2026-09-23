# Base Hyprland + Quickshell config

A starting-point dotfiles set for the Hyprland session added in
`import-05-desktop-hyprland.nix`. Not managed by NixOS/home-manager -- copy
it into your user's home directory once you're ready to try the session:

```bash
cp -r /etc/nixos/hypr-quickshell-config/hypr ~/.config/hypr
cp -r /etc/nixos/hypr-quickshell-config/quickshell ~/.config/quickshell
```

Then drop a wallpaper at `~/Pictures/wallpaper.jpg` (or edit the path in
`hypr/hyprpaper.conf`), log out, and pick "Hyprland" at the GDM login screen.

## What's here

- `hypr/hyprland.conf` -- look-and-feel, input, animations and keybindings,
  ported from Omarchy's actual default values (see the comment at the top of
  the file for what that means and doesn't mean).
- `hypr/hypridle.conf`, `hypr/hyprlock.conf`, `hypr/hyprpaper.conf` -- idle
  lock timings, lock screen styling, wallpaper daemon.
- `quickshell/shell.qml` -- a small top bar (workspaces, clock, volume,
  lock button) built on Quickshell's real documented API, styled to match.
  Extend it from here -- see the comment block at the bottom of the file.

## Keybindings worth knowing on first login

| Key | Action |
| --- | --- |
| `SUPER + RETURN` | Terminal (kitty) |
| `SUPER + SHIFT + RETURN` | Browser (firefox) |
| `SUPER + SPACE` | App launcher (wofi) |
| `SUPER + Q` / `SUPER + W` | Close window |
| `SUPER + 1..0` | Switch workspace |
| `SUPER + SHIFT + 1..0` | Move window to workspace |
| `SUPER + arrows` | Move focus |
| `SUPER + SHIFT + arrows` | Swap window |
| `SUPER + ESCAPE` | Lock screen |
| `SUPER + SHIFT + ESCAPE` | Exit Hyprland |
| `PRINT` | Region screenshot |
| `SUPER + CTRL + V` | Clipboard history (cliphist) |

Full list in `hypr/hyprland.conf`.
