{ config, pkgs, ... }:

# This is the helios-specific module: an Acer Predator Helios 300 with an
# Intel HD Graphics 630 iGPU and a GeForce GTX 1060 Mobile. Maggie's version
# of this file is AMD + ROCm instead.
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      intel-media-driver   # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver   # LIBVA_DRIVER_NAME=i965 (was `vaapiIntel`, renamed in nixpkgs)
      libva-vdpau-driver   # was `vaapiVdpau`, renamed in nixpkgs
      libvdpau-va-gl

      # nvidia
      nvidia-vaapi-driver
    ];
  };

  # NOTE: deliberately NO global LIBVA_DRIVER_NAME here.
  #
  # libva's auto-detection is per-device and already correct on this machine:
  # `vainfo --display drm --device /dev/dri/renderD128` with no env var set
  # resolves to iHD (Intel iHD driver 26.1.6) on its own.
  #
  # Setting it in environment.sessionVariables would apply to every process,
  # including ones using the NVIDIA node -- and forcing iHD onto
  # /dev/dri/renderD129 fails hard (va_openDriver() returns 18). That would
  # break VAAPI decode for anything run through nvidia-offload (moonlight-qt
  # being the obvious one here) for no gain.
  #
  # If a single app ever needs pinning, do it per-process instead:
  #   LIBVA_DRIVER_NAME=iHD obs
  # and use "i965" (intel-vaapi-driver, above) if iHD misbehaves on Kaby Lake.

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # The GTX 1060 is Pascal (GP106). NVIDIA dropped Maxwell/Pascal/Volta after
    # the 580 branch, so `stable`/`production` (595.x) will NOT drive this card.
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

    # Required for Wayland (GNOME and Hyprland sessions both need it).
    modesetting.enable = true;

    # Fine-grained power management (runtime D3) is Turing+ only, so it stays
    # off on this Pascal card.
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    nvidiaSettings = true;
    open = false;

    prime = {
      # Offload mode: the Intel iGPU drives the display, the Nvidia GPU is only
      # spun up when explicitly requested via `nvidia-offload <cmd>`.
      # (Don't enable sync.enable at the same time.)
      offload.enable = true;
      offload.enableOffloadCmd = true; # provides the `nvidia-offload` command

      #sync.enable = true;

      intelBusId = "PCI:0:2:0";  # 0000:00:02.0 Intel HD Graphics 630
      nvidiaBusId = "PCI:1:0:0"; # 0000:01:00.0 GeForce GTX 1060 Mobile
    };

    # Uncomment this if you face issues with the Nvidia Persistence Daemon
    # nvidiaPersistenced = true;
  };

  # For flatpaks, add __NV_PRIME_RENDER_OFFLOAD=1 (and
  # __GLX_VENDOR_LIBRARY_NAME=nvidia) as env variables via flatseal.

  users.users.pep.extraGroups = [ "video" "render" ];
}
