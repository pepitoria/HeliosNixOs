{ config, lib, pkgs, ... }:

{
  # Enable Nvidia drivers
  services.xserver.videoDrivers = [ "nvidia" ];
      
  # Driver Version
  hardware.nvidia = {
    # NOTE: `latest`/`stable` (595.x) dropped Pascal support - the 1060 needs legacy_580.
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = false;
    nvidiaSettings = true;
  };

  # PRIME
  hardware.nvidia.prime = {
  # sync mode (dont enable together with offload)
  #    sync.enable = true;

  # offload mode (dont enable together with sync)
    offload = {
      enable = true;
      enableOffloadCmd = true;
    };

    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
}
