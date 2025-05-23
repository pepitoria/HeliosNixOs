{ config, pkgs, lib, ... }:

{
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  # for nvidia
  nixpkgs.config.allowUnFree = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
      
      # nvidia
      nvidia-vaapi-driver
    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Enable modesetting for better integration with Wayland and modern Xorg setups
    modesetting.enable = true;

    # Enable Nvidia power management (optional, can sometimes cause issues with sleep/suspend)
    # For a GTX 1060, fine-grained power management might not be fully supported.
    powerManagement.enable = false; # Set to true if you want to try it, monitor for issues
    powerManagement.finegrained = false; # Likely not supported on 1060

    # Enable the Nvidia settings utility
    nvidiaSettings = true;
    open = false;

    # You can specify a particular Nvidia driver package if needed.
    # The 'production' package usually refers to the latest stable driver.
    # For a GTX 1060, `production` should work fine.
    # package = config.boot.kernelPackages.nvidiaPackages.production;

    # Prime setup for offloading (most common and recommended for laptops)
    prime = {
      # Enable offload mode: Intel GPU is primary, Nvidia GPU is used when explicitly requested.
      #offload.enable = true;
      #offload.enableOffloadCmd = true; # Enables the 'nvidia-offload' command

      sync.enable = true;

      intelBusId = "PCI:0:2:0"; # REPLACE WITH YOUR INTEL GPU BUS ID
      nvidiaBusId = "PCI:1:0:0"; # REPLACE WITH YOUR NVIDIA GPU BUS ID
    };

    # Uncomment this if you face issues with the Nvidia Persistence Daemon
    # nvidiaPersistenced = true;
  };

  # If you want to use the Nvidia GPU as the primary for everything (less common for laptops due to battery life)
  # You would disable prime.offload and potentially blacklist the Intel module.
  # boot.blacklistedKernelModules = [ "i915" ]; # Only if you want to ONLY use Nvidia
  # boot.kernelParams = [ "i915.modeset=0" ]; # Only if you want to ONLY use Nvidia

  # Optional: Environment variables for specific applications to ensure they use the Nvidia GPU
  # These are often set by `nvidia-offload` automatically, but you might need them for specific cases.
  #environment.sessionVariables = {
  #  __NV_PRIME_RENDER_OFFLOAD = "1";
  #  __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
  #  __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  #  __VK_LAYER_NV_optimus = "NVIDIA_only";
  #};
}
