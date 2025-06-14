{ config, pkgs, lib, ... }:

{

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
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
