{ nixpkgs ? <nixpkgs> }:

let

  pkgs = import nixpkgs {};

  deps = import ./deps.nix { inherit (pkgs) stdenv; };

  aurora = import ../../lib/aurora.nix { inherit pkgs; };

  helloWorldProcess = aurora.Process {
    name = "hello_world";
    cmdline = "${pkgs.nginx}/bin/${pkgs.python.executable} ${deps.helloWorldPy}/hello_world.py";
    propagatedBuildInputs = [
      pkgs.python
      pkgs.nginx
      deps.helloWorldPy
    ];
  };

  helloWorldTask = aurora.Task {
    processes = [ helloWorldProcess ];
    resources = {
      cpu = 1;
      ram = 1 * aurora.utils.MB;
      disk = 8 * aurora.utils.MB;
    };
  };

in aurora.Job {
  cluster = "devcluster";
  environment = "devel";
  role = "www-data";
  task = helloWorldTask;
}
