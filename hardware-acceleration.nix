{ config, pkgs, ... }:

# Intel-only variant, not imported by default (see configuration.nix).
{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver   # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver   # LIBVA_DRIVER_NAME=i965 (was `vaapiIntel`, renamed in nixpkgs)
      libva-vdpau-driver   # was `vaapiVdpau`, renamed in nixpkgs
      libvdpau-va-gl
    ];
  };
}
