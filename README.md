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
	git --reset hard HEAD

	# Install config
	ln -s ../miner.bitcoin.si/bin ../bin
	sudo ln -fs $(pwd)/<config name>.nix /etc/nixos/configuration.nix
	sudo ln -fs $(pwd)/password.nix /etc/nixos/password.nix

	# Rebuild system
	sudo nixos-rebuild switch
