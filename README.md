miner.bitcoin.si NixOS configuration
====================================

Installation:
-------------

	# Install dependencies
	nix-env -i git openssl

	# Clone
	git clone --recursive https://github.com/offlinehacker/miner.litecoin.si.git

	# Prepare gitcrypt
	cd miner.litecoin.si

	# Decrypt files
	git config gitcrypt.salt 0000000000000000
	git config gitcrypt.pass my-secret-phrase
	git config gitcrypt.cipher aes-256-ecb
	git config filter.encrypt.smudge "gitcrypt smudge"
	git config filter.encrypt.clean "gitcrypt clean"
	git config diff.encrypt.textconv "gitcrypt diff"
	git reset --hard HEAD


NOTE: If you are having problems with decrypting files, you should remove them and
then perform `git reset --hard HEAD` again.

Deployment:
-----------

	# Create a deployment with nixops
	nixops-create ./minerops.nix ./minerops-physical.nix -d minerops

	# Deploy your systems
	nixops deploy -d minerops

TODO:
-----

- Create a live install cd for automatic installations
- Switch master deployment from phyisical to ec2
- Fix ati xserver config generation to support multiple GPU-s
