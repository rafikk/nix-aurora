# nix-aurora

This repo is a proof-of-concept of integrating [Apache Aurora](http://aurora.apache.org/) with the [Nix](http://nixos.org/nix/) expression language, package manager, and build system. It contains the Hello World example from the [Aurora Tutorial](http://aurora.apache.org/documentation/latest/tutorial/) in the `examples/hello_world` directory.

## What's the idea

The idea is to build each Aurora job as a Nix derivation. The Nix derivation is itself composed of two derivations, one to generate the configuration file and another to generate the sandbox. Instead of defining a process to copy your code into the sandbox, Nix does the heavy lifting. Processes declare their job dependencies using the familiar Nix construct of `propagatedBuiltInputs`. The dependecies are built once, reside in the /nix/store, and the sandbox simply consists of a script per process that invokes the binaries using the full Nix store path.

## Steps to run

1. Start the Aurora Vagrant VM. Directions [here](http://aurora.apache.org/documentation/latest/vagrant/).
2. Install Nix using `curl https://nixos.org/nix/install | sh` and source `/home/vagrant/.nix-profile/etc/profile.d/nix.sh`
3. Clone this repo
4. Run `nix-build examples/hello_world`
5. Run `aurora job create --read-json devcluster/www-data/devel/hello_world ./result/config.json` to start the job

## Limitations

1. Currently this only works on a single-node cluster, i.e. where the scheduler and executor are on the same machine and share a Nix store. I still need to figure out the best way to distribute the sandbox to remote executor nodes.
2. Building the configuration file requires building the sandbox dependencies. This may or may not be a bad thing, but it's certainly a limitation.
