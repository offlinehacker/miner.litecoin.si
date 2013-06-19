{ config, pkgs, nodes,  ... }:

with pkgs.lib;

{
  require = [ ./base.nix ];

  # Force nameserver
  networking.nameservers = [ "8.8.8.8" "4.4.4.4" ];

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.videoDrivers = ["ati_unfree"];
  services.xserver.exportConfiguration = false;

  # Fix dri and link fglrx_dri.so
  system.activationScripts.drifix = ''
      # Create the required /usr/lib/dri/fglrx_dri.so;
      mkdir -p /usr/lib/dri
      ln -fs /run/opengl-driver/lib/fglrx_dri.so /usr/lib/dri/fglrx_dri.so
    '';

  system.activationScripts.xorg = ''
      LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/opengl-driver-32/lib ${pkgs.linuxPackages.ati_drivers_x11}/bin/aticonfig --initial --adapter=all --output=/etc/X11/xorg.conf
    '';

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
            remote ${nodes.master.config.deployment.targetHost}

            ca ${ca}
            cert ${cert}
            key ${key}
            dh ${dh}
            auth-user-pass /var/run/openvpn-pass.txt
          '';
        };
    };

  systemd.services."openvpn-client".preStart = ''
      echo -e "$(hostname).$(domainname)\npass" > /var/run/openvpn-pass.txt
  '';

  # Enable cgminer
  services.cgminer.enable = true;

  environment = {
    systemPackages = with pkgs; [
      cgminer
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
