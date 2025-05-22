{ config, pkgs, ... }:

{
# Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.pep = {
    isNormalUser = true;
    description = "pep";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
    shell = pkgs.fish;
  };
}
