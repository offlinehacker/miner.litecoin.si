let
  cgminer = rec {
    hwdefaults = {
      temp-cutoff = 87;
      temp-overheat = 82;
      temp-target = 79;
      temp-histeresys = 3;
      gpu-fan = "0-100";
    };

    hd7970.scrypt = {
      hardware = {
        kernel = "scrypt";
        intensity = 13;
        gpu-engine = 1105;
        gpu-memclock = 1500;
        lookup-gap = 2;
        shaders = 2048;
      } // hwdefaults;
    };
  };

  useHw = hw: config:
    if config.services.cgminer.config.scrypt then hw.scrypt.hardware
    else hw.sha.hardware;

in {
  luka =
    { config, pkgs, ... }:
    {
      require = [
        ./usb_boot.nix
      ];

      services.cgminer.hardware =
        [(useHw cgminer.hd7970 config) (useHw cgminer.hd7970 config)];

      networking.hostName = "luka";
      networking.domain = "miner.litecoin.si";

      deployment.targetEnv = "none";
      deployment.targetHost = "luka.miner.litecoin.si";
    };

  eva =
    { config, pkgs, ... }:
    {
      require = [
        ./usb_boot.nix
      ];

      services.cgminer.hardware =
        [(useHw cgminer.hd7970 config) (useHw cgminer.hd7970 config)];

      networking.hostName = "eva";
      networking.domain = "miner.litecoin.si";

      deployment.targetEnv = "none";
      deployment.targetHost = "eva.miner.litecoin.si";
    };

  pevec =
    { config, pkgs, ... }:
    {
      require = [
        ./usb_boot.nix
      ];

      services.cgminer.hardware =
        [(useHw cgminer.hd7970 config)];

      networking.hostName = "pevec";
      networking.domain = "miner.litecoin.si";

      deployment.targetEnv = "none";
      deployment.targetHost = "pevec.miner.litecoin.si";
    };

  blaz =
    { config, pkgs, ... }:
    {
      require = [
        ./usb_boot.nix
      ];

      services.cgminer.hardware =
        [(useHw cgminer.hd7970 config) (useHw cgminer.hd7970 config)];

      networking.hostName = "blaz";
      networking.domain = "miner.litecoin.si";

      deployment.targetEnv = "none";
      deployment.targetHost = "blaz.miner.litecoin.si";
    };

  master =
    { config, pkgs, ... }:
    {
      require = [
        <nixos/modules/virtualisation/amazon-image.nix>
      ];

      swapDevices = [{
        device = "/var/swapfile";
      }];

      deployment.targetHost = "miner.litecoin.si";
      networking.privateIPv4 = "10.4.0.1";
   };
}
