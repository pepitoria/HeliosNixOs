{ config, pkgs, ... }:

{
  # Docker
  virtualisation.docker.enable = true;
  users.extraGroups.docker.members = [ "pep" ];

  # Steam (needs special configuration for gaming)
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # OpenSSH
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = null;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Sunshine (remote desktop)
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
}
