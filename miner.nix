# the system.  Help is available in the configuration.nix(5) man page
# or the NixOS manual available on virtual console 8 (Alt+F8).

{ config, pkgs, ... }:

with pkgs.lib;

{
  require =
    [ # Include the results of the hardware scan.
      ./hardware.nix
    ];

  networking.hostName = "labelflash.miner.litecoin.si";

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
  services.xserver.exportConfiguration = true;

  system.activationScripts.drifix = stringAfter [ "binsh" ]
    ''
      # Create the required /usr/lib/dri/fglrx_dri.so;
      ln -fs /run/opengl-driver/lib/fglrx_dri.so /usr/lib/dri/fglrx_dri.so
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

  environment = {
   systemPackages = with pkgs; [
     cgminer
   ];

   etc.opencl = {
     source = "${pkgs.amdappsdk}/etc/OpenCL";
     target = "OpenCL";
   };
  };
}
