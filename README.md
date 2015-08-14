# nix-aurora

This repo is a proof-of-concept for integrating [Apache Aurora](http://aurora.apache.org/) with the [Nix](http://nixos.org/nix/) expression language, package manager, and build system.

## What's the idea?

The idea is to define Aurora job configurations using Nix expressions. Each Nix expression defines a single Aurora Job (using the typical Task/Process/Constraint/Resources/etc. schema) where the build result is a JSON configuration file that can be passed to the Aurora CLI. Since the job is defined and built using Nix, all referenced packages and dependencies are built transparently. This means you can avoid defining extra processes for versioning and initialization. If your process depends on a software package, simply reference the package in `cmdline` and Nix will build the package and provide a reference to the dependency in the Nix store. For example, if you want to run an Nginx process, you can create a process with `cmdline = "${pkgs.nginx}/bin/nginx ..."`. When the job is built, Nix will build Nginx and interpolate the path into the configuration. Further, since the Nix store path is composed of a cryptographic hash of the package and its dependencies, updating a package automatically updates the configuration, so you can avoid versioning "tricks". Any time a dependency is changed, the config is changed.

## How does this work?

An Aurora job is composed of a Task which consists of one or more Processes. In addition to building the Job as a Nix derivation, every Process is also built as a Nix derivation (the output is a bash script with `cmdline` as its contents). The JSON configuration creates an "init" process for each Process specified in the Job which ensures this bash script exists in the Nix store. Since referenced packages are dependencies of the Process derivation, those packages then also exist in the Nix store. The configuration then adds a Constraint for each process that ensures its init process completes before the corresponding Process is launched.

## Steps to run

1. Start the Aurora Vagrant VM. Directions [here](http://aurora.apache.org/documentation/latest/vagrant/).
2. Install Nix using `curl https://nixos.org/nix/install | sh` and source `/home/vagrant/.nix-profile/etc/profile.d/nix.sh`
3. `git clone https://github.com/rafikk/nix-aurora.git`
4. Run `aurora job create --read-json devcluster/vagrant/devel/hello_world $(nix-build --no-out-link examples/hello_world)` to start the job

If you would just like to see the JSON configuration, install Nix and run `cat $(nix-build ./nix-aurora/examples/hello_world --no-out-link) | python -m json.tool`. Here's the output running on my Mac laptop:

```json
{
    "cluster": "devcluster",
    "environment": "devel",
    "name": "hello_world",
    "role": "vagrant",
    "service": true,
    "task": {
        "constraints": [
            {
                "order": [
                    "nix_init_hello_world",
                    "hello_world"
                ]
            }
        ],
        "name": "hello_world",
        "processes": [
            {
                "cmdline": ". /home/vagrant/.nix-profile/etc/profile.d/nix.sh\nnix-store --add-root .gc/hello_world --indirect -r /nix/store/4c6z04825b9a49vlsp2mk0rg19ybyd5f-aurora-process-devcluster-vagrant-devel-hello_world-hello_world\n",
                "name": "nix_init_hello_world"
            },
            {
                "cmdline": "/nix/store/q41nkp3p684xyjlnv02f8hnid234z4n8-python-2.7.10/bin/python2.7 /nix/store/53fxpfg3nkkjvzfvh54r8ccms2b3l7iz-hello_world.py/hello_world.py",
                "name": "hello_world"
            }
        ],
        "resources": {
            "cpu": 1,
            "disk": 8388608,
            "ram": 1048576
        }
    }
}
```

## Limitations

1. Currently this only works on a single-node Vagrant cluster. In order to run this on a multi-node production cluster, Nix must be running in multi-user daemon mode, and a binary cache (or another distribution mechanism) would be required.
