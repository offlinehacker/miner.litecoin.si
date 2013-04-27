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

  networking.nameservers = [ "127.0.0.1" ];

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
-      ln -sfn "${config.system.build.binsh}/bin/sh" /bin/.bash.tmp
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

    dnsmasq = {
      enable = true;
      servers = [ "8.8.8.8" "172.16.0.23" ];
      extraConfig = ''
        addn-hosts=/etc/hosts.openvpn-clients
      '';
    };

    openvpn.servers = {
      server =
        let
          # We should write text files, to maintain production stable system
          # if user changes config
          ca = pkgs.writeText "ca.crt" (builtins.readFile ./keys/ca.crt);
          cert = pkgs.writeText "miner.crt" (builtins.readFile ./keys/miner.crt);
          key = pkgs.writeText "miner.key" (builtins.readFile ./keys/miner.key);
          dh = pkgs.writeText "dh1024.pem" (builtins.readFile ./keys/dh1024.pem);
          verify = ''
            #!/bin/sh
            exit 0
          '';
          learnAddresses = ''
#!/bin/sh
# openvpn learn-address script to manage a hosts-like file
# - intended to allow dnsmasq to resolve openvpn clients
#   addn-hosts=/etc/hosts.openvpn-clients
# - written for openwrt (busybox), but should work most anywhere
#
# Changelog
# 2006-10-13 BDL original
HOSTS=/etc/hosts.openvpn-clients

h=$(${pkgs.coreutils}/bin/basename "$HOSTS")
LOCKFILE="/var/run/$h.lock"

IP="$2"
CN="$3"

case "$1" in
  add|update)
    if [ -z "$IP" -o -z "$CN" ]; then
        echo "$0: IP and/or Common Name not provided" >&2
        exit 0
    fi
  ;;
  delete)
    if [ -z "$IP" ]; then
        echo "$0: IP not provided" >&2
        exit 0
    fi
  ;;
   *)
    echo "$0: unknown operation [$1]" >&2
    exit 1
  ;;
esac


# serialise concurrent accesses
[ -x lock ] && lock "$LOCKFILE"

FQDN="$CN"

# busybox mktemp must have exactly six X's
t=$(${pkgs.coreutils}/bin/mktemp "/tmp/$h.XXXXXX")
if [ $? -ne 0 ]; then
    echo "$0: mktemp failed" >&2
    exit 1
fi


case "$1" in

  add|update)
    ${pkgs.gawk}/bin/awk '
        # update/uncomment address|FQDN with new record, drop any duplicates:
        $2 == "'"$FQDN"'" \
            { if (!m) print "'"$IP"'\t'"$FQDN"'"; m=1; next }
        { print }
        END { if (!m) print "'"$IP"'\t'"$FQDN"'" }           # add new address to end
    ' "$HOSTS" > "$t" && ${pkgs.coreutils}/bin/cat "$t" > "$HOSTS"
  ;;

  delete)
    ${pkgs.gawk}/bin/awk '
        # no FQDN, comment out all matching addresses (should only be one)
        $1 == "'"$IP"'" { print "#" $0; next }
        { print }
    ' "$HOSTS" > "$t" && ${pkgs.coreutils}/bin/cat "$t" > "$HOSTS"
  ;;

esac

# signal dnsmasq to reread hosts file
[ -f /var/run/dnsmasq.pid ] && ${pkgs.coreutils}/bin/kill -HUP $(${pkgs.coreutils}/bin/cat /var/run/dnsmasq.pid)

${pkgs.coreutils}/bin/rm "$t"

[ -x lock ] && lock -u "$LOCKFILE"
exit 0
'';
        in {
          config = ''
            dev tun
            proto tcp
            server 10.4.0.0 255.255.255.0
            management 127.0.0.1 5094

            ca ${ca}
            cert ${cert}
            key ${key}
            dh ${dh}
            duplicate-cn
            username-as-common-name
            auth-user-pass-verify ${pkgs.writeScript "openvpn-server-verify" verify} via-file

            learn-address ${pkgs.writeScript "openvpn-server-learn" learnAddresses}
            script-security 2
            log /var/log/openvpn.log
          '';
        };
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
          servedDirs = [
            { urlPath = "/static";
              dir = "/home/admin/www";
            }
          ];
        }
      ];
    };

  };
}
