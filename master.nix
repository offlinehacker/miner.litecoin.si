{ config, pkgs, modulesPath, ... }:

with pkgs.lib;

{
  require = [
    "${modulesPath}/virtualisation/amazon-image.nix" 
  ];

  swapDevices = [
    { device = "/var/swapfile"; }
  ];

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  environment.shellInit = ''export PATH=~/bin/:$PATH'';

  users.extraUsers.admin =
    { description = "me, the admin";
      home = "/home/admin";
      createHome = true;
      useDefaultShell = true;
      extraGroups = ["wheel" "users"];
      group = "users";
      openssh.authorizedKeys.keys = (import ./password.nix).adminKeys;
    };

  system.activationScripts.binbash = stringAfter [ "binsh" ]
    ''
      # Create the required /bin/bash symlink;
      mkdir -m 0755 -p /bin
      ln -sfn "${config.system.build.binsh}/bin/sh" /bin/.bash.tmp
      mv /bin/.bash.tmp /bin/bash # atomically replace /bin/sh
    '';

  services = {

    postgresql = {
      enable = true;
      package = pkgs.postgresql92;
    };

    # Enable the OpenSSH daemon.
    openssh.enable = true;

    # turn off rate limiting for journald
    journald.rateLimitBurst = 0;

    zabbixServer = {
      enable = true;
      dbPassword = (import ./password.nix).zabbix;
    };

    httpd = {
      enable = true;
      multiProcessingModule = "worker";
      logPerVirtualHost = true;
      adminAddr = "jakahudoklin@gmail.com";
      hostName = "localhost";

      extraModules = ["deflate"];
      extraConfig =
        ''
          <Location /server-status>
            SetHandler server-status
            Allow from 127.0.0.1 # If using a remote host for monitoring replace 127.0.0.1 with its IP.
            Order deny,allow
            Deny from all
          </Location>

          ExtendedStatus On

          StartServers 15
        '';

      phpOptions =
        ''
          max_input_time = 600
          memory_limit = "256M"
          upload_max_filesize = "16M"
        '';

      virtualHosts = [
        { # Catch-all site.
          hostName = "www.litecoin.si";
          globalRedirect = "http://litecoin.si/";
        }
        { hostName = "miner.litecoin.si";
          enableUserDir = true;
          extraSubservices = [
            { serviceType = "zabbix";
              urlPrefix = "/zabbix";
            }
          ];
        }
      ];
    };

  };
}
