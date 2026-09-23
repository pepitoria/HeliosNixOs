{ config, pkgs, ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Maggie uses the Zen kernel, but we can't here: zen currently tracks 7.2.x,
  # and the NVIDIA 580 branch (the last one supporting this Pascal card, see
  # import-08-gpu.nix) does not compile against it --
  #   nvidia/os-interface.c:732: implicit declaration of function 'strncpy'
  # XanMod is the same idea as Zen -- desktop/low-latency scheduler patches --
  # but tracks 6.18.x, where the 580 modules build fine.
  #
  # boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelPackages = pkgs.linuxPackages_xanmod;
}
