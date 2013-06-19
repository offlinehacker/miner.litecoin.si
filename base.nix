{ config, pkgs, ... }:

with pkgs.lib;

{
  # Select internationalisation properties.
  i18n = {
    consoleFont = "lat9w-16";
    consoleKeyMap = "slovene";
    defaultLocale = "sl_SI.UTF-8";
  };

  #  Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable sudo without password
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  # Add admin user
  users.extraUsers.admin =
    { description = "me, the admin";
      home = "/home/admin";
      createHome = true;
      useDefaultShell = true;
      extraGroups = ["wheel" "users"];
      group = "users";
      openssh.authorizedKeys.keys = (import ./password.nix).adminKeys;
    };

  users.extraUsers.root.openssh.authorizedKeys.keys = (import ./password.nix).adminKeys;

  system.activationScripts.binbash = stringAfter [ "binsh" ]
    ''
      # Create the required /bin/bash symlink;
      mkdir -m 0755 -p /bin
      ln -sfn "${config.system.build.binsh}/bin/sh" /bin/.bash.tmp
      mv /bin/.bash.tmp /bin/bash # atomically replace /bin/sh
    '';

}
