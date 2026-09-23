{ config, pkgs, lib, ... }:

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

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # The GTX 1060 is Pascal (GP106). NVIDIA dropped Maxwell/Pascal/Volta after
    # the 580 branch, so `stable`/`production` (595.x) will NOT drive this card.
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

    # Enable modesetting for better integration with Wayland and modern Xorg setups
    modesetting.enable = true;

    # Fine-grained power management (runtime D3) is Turing+ only, so it stays off
    # on this Pascal card.
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # Enable the Nvidia settings utility
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

  # For flatpaks, add __NV_PRIME_RENDER_OFFLOAD=1 (and __GLX_VENDOR_LIBRARY_NAME=nvidia)
  # as env variables for the app using flatseal.
}
