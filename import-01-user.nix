{ config, pkgs, ... }:

{
# Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.pep = {
    isNormalUser = true;
    description = "pep";
    # "adbusers" is only defined when programs.adb.enable is on, which it
    # isn't here -- android dev is commented out in import-06-packages.nix.
    extraGroups = [ "networkmanager" "wheel" /* "adbusers" */ "kvm" "dialout"];
    packages = with pkgs; [
    #  thunderbird
    ];
    shell = pkgs.fish;
  };
}
