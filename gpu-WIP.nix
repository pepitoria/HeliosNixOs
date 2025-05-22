{ config, lib, pkgs, ... }:

{
  # Enable Nvidia drivers
  services.xserver.videoDrivers = [ "nvidia" ];
      
  # Driver Version
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.latest;
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
