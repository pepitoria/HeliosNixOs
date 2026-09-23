{ config, pkgs, ... }:

# NOTE: on maggie quickshell came from <unstable>. In the 26.05 channel it is
# in stable (quickshell 0.3.0), so this machine needs no unstable channel.
# If it is ever needed again: run scripts/add-channel-unstable.sh and
# uncomment the let bindings below.
let
  # baseconfig = { allowUnfree = true; };
  # unstable = import <unstable> { config = baseconfig; };

  # Formats `hyprctl binds` into "MODS + KEY   description" lines. Records
  # are separated by blank lines, fields are "name: value". modmask is a
  # libinput bitmask: 1 SHIFT, 4 CTRL, 8 ALT, 64 SUPER. Binds without a
  # description (the bindm mouse ones, which can't take one) fall back to
  # showing their dispatcher and args.
  keybindsAwk = pkgs.writeText "hypr-keybinds.awk" ''
    BEGIN { RS = ""; FS = "\n" }
    {
      modmask = 0; key = ""; desc = ""; disp = ""; arg = ""
      for (i = 1; i <= NF; i++) {
        l = $i
        sub(/^[ \t]+/, "", l)
        p = index(l, ":")
        if (p == 0) continue
        name = substr(l, 1, p - 1)
        val = substr(l, p + 2)
        if (name == "modmask") modmask = val + 0
        else if (name == "key") key = val
        else if (name == "description") desc = val
        else if (name == "dispatcher") disp = val
        else if (name == "arg") arg = val
      }
      if (key == "") next
      mods = ""
      if (int(modmask / 64) % 2) mods = mods "SUPER + "
      if (int(modmask / 4) % 2)  mods = mods "CTRL + "
      if (int(modmask / 8) % 2)  mods = mods "ALT + "
      if (modmask % 2)           mods = mods "SHIFT + "
      label = desc
      if (label == "") { label = disp; if (arg != "") label = label " " arg }
      printf "%-32s %s\n", mods key, label
    }
  '';
in {
  # Hyprland is offered as an alternative session from the existing GDM
  # login screen (services.displayManager.gdm.enable, set in
  # import-05-desktop-gnome.nix). programs.hyprland.enable registers a
  # Wayland session that GDM picks up automatically -- no display-manager
  # changes needed, and GNOME stays as the fallback.
  programs.hyprland.enable = true;

  # Screen lock + idle daemon. Enabling hyprlock also pulls in
  # services.hypridle.enable and the PAM service it needs.
  programs.hyprlock.enable = true;

  # Bluetooth GUI manager -- GNOME's is built into gnome-shell, which
  # Hyprland doesn't have. This wires up blueman's package plus its D-Bus
  # mechanism service (needed for privileged actions like toggling the
  # adapter from the GUI), not just the bare binary.
  services.blueman.enable = true;

  # File manager ($fileManager in hyprland.conf). programs.thunar wires up
  # its D-Bus/systemd units and xfconf, which Thunar needs to persist its
  # own settings -- the bare package alone isn't enough.
  programs.thunar.enable = true;
  # Thumbnails for images/video in Thunar. Not pulled in by anything else.
  services.tumbler.enable = true;
  # Trash, removable-media mounting, network shares. GNOME already enables
  # this, but state it here so the Hyprland session doesn't silently depend
  # on GNOME staying installed.
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    quickshell # in stable as of 26.05 (was unstable.quickshell on maggie)

    hyprpaper # wallpaper daemon
    mako # notification daemon (fallback until/unless Quickshell's own is configured)
    wl-clipboard
    cliphist
    grim
    slurp
    swappy
    playerctl
    brightnessctl
    pavucontrol
    networkmanagerapplet
    nwg-look # GTK/icon theme switcher, replaces gnome-tweaks under Hyprland
    wofi # app launcher / dmenu replacement, used by the base hyprland.conf
    kitty # terminal, used as $terminal in the base hyprland.conf

    # polkit_gnome's agent binary lives in libexec, which isn't linked onto
    # PATH by environment.systemPackages -- wrap it under a stable name so
    # `exec-once = polkit-agent` in hyprland.conf works without a hardcoded
    # store path.
    (writeShellScriptBin "polkit-agent" ''
      exec ${polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
    '')

    # SUPER + K cheat sheet: every keybind, searchable. Descriptions come
    # from the bindd/bindde/binddel/binddl lines in hyprland.conf. This is
    # a reference only -- picking an entry doesn't run it, deliberately, so
    # a fuzzy match can't fire "Exit Hyprland" or "Suspend" by accident.
    # hyprctl is taken from PATH since this only runs inside a session.
    (writeShellScriptBin "hypr-keybinds" ''
      hyprctl binds \
        | ${gawk}/bin/awk -f ${keybindsAwk} \
        | ${wofi}/bin/wofi --dmenu -i -p Keybindings \
            --width 750 --height 500 --cache-file /dev/null >/dev/null
    '')
  ];

  # Hyprland, hyprlock, hypridle, hyprpaper and Quickshell are all configured
  # via dotfiles under ~/.config (hypr/hyprland.conf, hypr/hypridle.conf,
  # hypr/hyprlock.conf, hypr/hyprpaper.conf, quickshell/). None of that is
  # managed by this repo -- there's no home-manager wired in (see CLAUDE.md).
  # Hyprland writes a minimal default hyprland.conf on first login if one
  # doesn't exist yet, so the session is usable immediately; everything else
  # (bar, launcher, lock screen styling) needs those dotfiles written by hand.
}
