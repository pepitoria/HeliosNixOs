{ config, pkgs, ... }:

# NOTE: maggie pulls several packages from <unstable>. Everything this machine
# needs is in the 26.05 stable channel, so there is no unstable channel here.
# To bring it back: run scripts/add-channel-unstable.sh, uncomment the let
# bindings below, and prefix the packages with `unstable.`.
#
# let
#   baseconfig = { allowUnfree = true; };
#   unstable = import <unstable> { config = baseconfig; };
# in
{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable programs
  programs.firefox.enable = true;
  programs.fish = {
    enable = true;
    # FLUTTER_SDK is commented out along with flutter itself (dev stuff is
    # not installed on this machine).
    # shellInit = ''
    #   set -gx FLUTTER_SDK ${pkgs.flutter}
    # '';
  };

  programs.appimage.enable = true;
  programs.appimage.binfmt = true;
  programs.appimage.package = pkgs.appimage-run.override {
    extraPkgs = pkgs: with pkgs; [
      elfutils
      zstd
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
    ];
    # Some AppImages (e.g. linuxdeploy-based ones bundling WebKitGTK) clear
    # GST_PLUGIN_SYSTEM_PATH_1_0 at startup to avoid loading a possibly
    # ABI-incompatible host GStreamer. GST_PLUGIN_PATH_1_0 is a separate,
    # untouched variable that GStreamer scans just the same.
    buildFHSEnv =
      args:
      pkgs.buildFHSEnv (
        args
        // {
          profile = (args.profile or "") + ''
            export GST_PLUGIN_PATH_1_0="/usr/lib/gstreamer-1.0:/usr/lib32/gstreamer-1.0''${GST_PLUGIN_PATH_1_0:+:$GST_PLUGIN_PATH_1_0}"
          '';
        }
      );
  };

  # Flatpak (kept as backup, auto-install disabled since we use native packages now)
  services.flatpak.enable = true;
  # systemd.services.flatpak-repo = {
  #   wantedBy = [ "multi-user.target" ];
  #   path = [ pkgs.flatpak ];
  #   script = ''
  #     flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  #     flatpak update
  #     flatpak install -y flathub com.spotify.Client
  #   '';
  # };

  # we need this because of the claude plugin in visual studio code. it comes with a precompiled binary
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    # add more if needed
    zstd
    libGL
    glib
    elfutils
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # editors
    vim
    neovim

    # system tools
    kmod
    pciutils
    fastfetch
    htop
    nvtopPackages.full
    dysk
    zellij

    # dev
    git
    vscode
    ffmpeg
    #claude-code
    #gemini-cli

    # apps
    spotify
    gimp
    discord
    ferdium
    moonlight-qt
    filezilla

    # containers
    #distrobox

    # android dev -- not installed on this machine
    #android-tools
    #android-studio-tools
    #android-studio
    #androidenv.androidPkgs.androidsdk
    #genymotion

    # flutter -- not installed on this machine
    #flutter
  ];
}
