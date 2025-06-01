{ config, pkgs, ... }:

let
  baseconfig = { allowUnfree = true; };
  unstable = import <unstable> { config = baseconfig; };
in {
  # Install firefox.
  programs.firefox.enable = true;
  programs.fish.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    neovim
    pciutils
    fastfetch
    htop
    nvtopPackages.full
    fish
    dysk
    
    # gnome
    gnome-software
    gnome-tweaks

    # dev
    git
    vscode
    
    # containers
    distrobox
    
    # android dev
    unstable.android-tools
    unstable.android-studio
    #genymotion

  ];

  # Flatpak
  services.flatpak.enable = true;
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      flatpak update
      flatpak install -y flathub com.spotify.Client
      flatpak install -y flathub com.valvesoftware.Steam
      flatpak install -y flathub org.gimp.GIMP
      flatpak install -y flathub com.discordapp.Discord
      flatpak install -y flathub com.github.tchx84.Flatseal
      flatpak install -y flathub org.ferdium.Ferdium
      flatpak install -y flathub com.moonlight_stream.Moonlight
    '';
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome = {
        enable = true;
        extraGSettingsOverrides =
          let
            #workspaces = map toString (lib.lists.range 1 3);
          in ''
            [org.gnome.desktop.wm.preferences]
            button-layout=':minimize,maximize,close'
          '';
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "es";
    variant = "";
  };

  # docker
  virtualisation.docker.enable = true;
  users.extraGroups.docker.members = [ "pep" ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # OpenSSH
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = null;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

}
