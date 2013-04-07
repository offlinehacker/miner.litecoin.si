{ config, pkgs, modulesPath, ... }:

{
  require = [ "${modulesPath}/virtualisation/amazon-image.nix" ];

  swapDevices = [
    { device = "/var/swapfile"; }
  ];

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  users.extraUsers.offlinehacker =
    { description = "me, the admin";
      home = "/home/offlinehacker";
      createHome = true;
      useDefaultShell = true;
      extraGroups = ["wheel" "users"];
      group = "users";
      openssh.authorizedKeys.keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3/Zo9NvIC+qzmSR5xjZUZMOaMi8ZZZ+6t3mSasdGg+Es51Qg8chz77bO4Qf++VZaMO+NBwzWyvaYvf284zpQMRWmTR6ODvj/LQNuo5/DdAhFXrNmEndfWU7gs3TreTdUGCTJo5Vgkc9WpxP/BJuA3OGrhMWUVzhlmRpYAi9/n3I2EuOvD8Ws1P92qD5oGIP1Vgn1lWXp6XinbWpVsbjzJRYQ7igIr7P/XgFVVzZylKBDepJKCMoC9e1C3M6IHRX57IUCif2E7PZ/r6PWp0UQ2fR7bC5YVqniUp5so7IxlaX4rD6yFuVsrGN8tBVMRHzIck/7XCZmRcQyc6V7FGOQp offlinehacker@ip-10-98-19-15.ec2.internal"];
    };

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
      dbPassword = "test";
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
