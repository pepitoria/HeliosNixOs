{ config, pkgs, ... }:

{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome = {
        enable = true;
        extraGSettingsOverrides = ''
            [org.gnome.desktop.wm.preferences]
            button-layout=':minimize,maximize,close'

            [org.gnome.desktop.interface]
            cursor-theme='Adwaita'
          '';
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "es";
    variant = "";
  };

  # GNOME extras
  environment.systemPackages = with pkgs; [
    gnome-software
    gnome-tweaks
  ];
}
