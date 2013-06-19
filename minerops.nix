let
  cgminer = rec {
    confdefaults = {allow? "10.0.0.1"}: {
      api-listen = true;
      api-network = true;
      api-allow = "W:127.0.0.1,R:${allow}";
      auto-fan = true;
      auto-gpu = true;
      log = 10;
      no-pool-disable = true;
      scrypt = false;
    };

    scrypt = {
      scrypt = true;
      gpu-threads = 2;
    };

    # List of all pools for different hash types
    pools = {
      luka_lc = {
        scrypt = true;
        pool = name: [{
          url = "http://us.litecoinpool.org:9332";
          user = "aircrack." + name;
          pass = "x";
        }];
      };

      luka_fc = {
        scrypt = true;
        pool = name: [{
          url = "stratum+tcp://pool.fcpool.com:3334";
          user = "offlinehacker." + name;
          pass = "x";
        }
        {
          url = "http://www.fcpool.com:8377";
          user = "offlinehacker." + name;
          pass = "x";
        }];
      };
    };

  };

  miner =
    { cgminer_config? {},
      pools? cgminer.pools.luka_lc
    }:
    { config, pkgs, nodes, ... }:
    let
      master = nodes.master.config;
      crypto_config = if pools.scrypt then cgminer.scrypt else {};
    in {
      require = [ ./miner.nix ];

      services.cgminer.config =
        cgminer.confdefaults {allow = master.networking.privateIPv4;} // crypto_config // cgminer_config;
      services.cgminer.pools = pools.pool config.networking.hostName;
    };

  master =
    { config, pkgs, nodes, ... }:
    {
      require = [ ./master.nix ];
    };

in {
  network.description = "Mining network";

  luka = miner { pools = cgminer.pools.luka_lc; };
  eva = miner { pools = cgminer.pools.luka_lc; };
  pevec = miner { pools = cgminer.pools.luka_lc; };
  blaz = miner { pools = cgminer.pools.luka_lc; };

  master = master;
}
