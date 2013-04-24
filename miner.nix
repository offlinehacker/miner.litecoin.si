# the system.  Help is available in the configuration.nix(5) man page
# or the NixOS manual available on virtual console 8 (Alt+F8).

{ config, pkgs, ... }:

with pkgs.lib;

{
  require =
    [ # Include the results of the hardware scan.
      ./hardware.nix
    ];

  networking.hostName = "worker.miner.litecoin.si";
  networking.nameservers = [ "8.8.8.8" "4.4.4.4" ];

  # Select internationalisation properties.
  i18n = {
    consoleFont = "lat9w-16";
    consoleKeyMap = "slovene";
    defaultLocale = "sl_SI.UTF-8";
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.videoDrivers = ["ati_unfree"];
  services.xserver.exportConfiguration = false;

  system.activationScripts.drifix =
    ''
      # Create the required /usr/lib/dri/fglrx_dri.so;
      mkdir -p /usr/lib/dri
      ln -fs /run/opengl-driver/lib/fglrx_dri.so /usr/lib/dri/fglrx_dri.so
    '';

  system.activationScripts.xorg =
    ''
      LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/opengl-driver-32/lib ${pkgs.linuxPackages.ati_drivers_x11}/bin/aticonfig --initial --adapter=all --output=/etc/X11/xorg.conf
    '';

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  users.extraUsers.admin =
    { description = "me, the admin";
      home = "/home/admin";
      createHome = true;
      useDefaultShell = true;
      extraGroups = ["wheel" "users"];
      group = "users";
      openssh.authorizedKeys.keys = (import ./password.nix).adminKeys;
    };

  services.openvpn.servers = {
      client =
        let
          # We should write text files, to maintain production stable system
          # if user changes config
          ca = pkgs.writeText "ca.crt" (builtins.readFile ./keys/ca.crt);
          cert = pkgs.writeText "miner.crt" (builtins.readFile ./keys/worker.crt);
          key = pkgs.writeText "miner.key" (builtins.readFile ./keys/worker.key);
          dh = pkgs.writeText "dh1024.pem" (builtins.readFile ./keys/dh1024.pem);
        in {
          config = ''
            client
            remote miner.litecoin.si
            dev tun
            ca ${ca}
            cert ${cert}
            key ${key}
            dh ${dh}

            log /var/log/openvpn.log
            verb 6
          '';
        };
    };

  services.zabbixAgent = {
    enable = true;
    server = "10.4.0.1";
    extraConfig = "
      EnableRemoteCommands=1
    ";
  };

  systemd.services."cgminer" = {
    after = [ "display-manager.target" "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.cgminer ];
    environment = { 
      LD_LIBRARY_PATH = ''/run/opengl-driver/lib:/run/opengl-driver-32/lib''; 
      DISPLAY = ":0";
      GPU_MAX_ALLOC_PERCENT = "100";
      GPU_USE_SYNC_OBJECTS = "1";   
    };
    script = ''
      MAC=$(${pkgs.nettools}/bin/ifconfig | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | tr -d ":")

      ${pkgs.curl}/bin/curl -k https://raw.github.com/offlinehacker/miner.litecoin.si/master/cgminer.conf > /etc/cgminer.conf
      ${pkgs.cgminer}/bin/cgminer -T -c /etc/cgminer.conf \
        -o http://us.litecoinpool.org:9332 -u aircrack.$MAC -p x
    '';
    serviceConfig.Restart = "always";
    serviceConfig.RestartSec = 10;
  };
  
  environment = {
   systemPackages = with pkgs; [
     cgminer
     git
     openssl
     screen
   ];

   shellInit = ''
     export DISPLAY=:0
     export GPU_MAX_ALLOC_PERCENT=100
     export GPU_USE_SYNC_OBJECTS=1
   '';

   etc.opencl = {
     source = "${pkgs.amdappsdk}/etc/OpenCL";
     target = "OpenCL";
   };
  };
}
