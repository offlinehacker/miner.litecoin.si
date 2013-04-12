# This is a generated file.  Do not modify!
# Make changes to /etc/nixos/configuration.nix instead.
{ config, pkgs, ... }:

{
  require = [
    <nixos/modules/installer/scan/not-detected.nix>
  ];

  boot.initrd.kernelModules = [ "ahci" "ohci_hcd" "ehci_hcd" "pata_atiixp" "firewire_ohci" "xhci_hcd" "pata_jmicron" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  nix.maxJobs = 4;

  fileSystems."/".device = "/dev/disk/by-label/nixos";
  swapDevices =
    [ { device = "/dev/disk/by-label/swap"; }
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";
}
