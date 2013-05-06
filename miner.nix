# the system.  Help is available in the configuration.nix(5) man page
# or the NixOS manual available on virtual console 8 (Alt+F8).

{ config, pkgs, ... }:

with pkgs.lib;

{
  require =
    [ # Include the results of the hardware scan.
      ./hardware.nix
    ];

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

  system.activationScripts.drifix = ''
      # Create the required /usr/lib/dri/fglrx_dri.so;
      mkdir -p /usr/lib/dri
      ln -fs /run/opengl-driver/lib/fglrx_dri.so /usr/lib/dri/fglrx_dri.so
    '';

  system.activationScripts.xorg = ''
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
            dev tun
            proto tcp
            remote miner.litecoin.si

            ca ${ca}
            cert ${cert}
            key ${key}
            dh ${dh}
            auth-user-pass /var/run/openvpn-pass.txt
          '';
        };
    };

  systemd.services."openvpn-client".preStart = ''
      MAC=$(cat /sys/class/net/enp3s0/address | tr -d ":")
      echo -e "$MAC.miner.litecoin.si\npass" > /var/run/openvpn-pass.txt

      # TODO: put this somewhere else
      hostname "$MAC.miner.litecoin.si"
  '';

  services.zabbixAgent = {
    enable = true;
    server = "10.4.0.1";
    extraConfig = "
      EnableRemoteCommands=1
      Hostname=miner.litecoin.si
      DisableActive=0
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
      MAC=$(${pkgs.nettools}/bin/ifconfig -a | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | tr -d ":")

      CONFIG="https://raw.github.com/offlinehacker/miner.litecoin.si/master/cgminer.conf"
      PARAMS_CONFIG="https://raw.github.com/offlinehacker/miner.litecoin.si/master/cgminer.params"

      if [ 200 -eq $(${pkgs.curl}/bin/curl -k --write-out %{http_code} --silent --output /dev/null $PARAMS_CONFIG.$MAC) ]; then
        PARAMS=$(${pkgs.curl}/bin/curl -k $PARAMS_CONFIG.$MAC)
      else
        PARAMS=$(${pkgs.curl}/bin/curl -k $PARAMS_CONFIG)
      fi

      ${pkgs.curl}/bin/curl --silent -k $CONFIG > /etc/cgminer.conf
      ${pkgs.cgminer}/bin/cgminer -T -c /etc/cgminer.conf $(eval echo $PARAMS)
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
     nmap
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
