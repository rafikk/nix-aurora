{ nixpkgs ? <nixpkgs> }:

let

  pkgs = import nixpkgs {};

  files = pkgs.stdenv.mkDerivation rec {
    name = "files";
    src = ./files;
    buildCommand = "mkdir -p $out && cp ${src}/* $out/";
  };

  aurora = import ../../lib/aurora.nix { inherit pkgs; };

  helloWorldProcess = aurora.Process {
    name = "hello_world";
    cmdline = "${pkgs.python}/bin/${pkgs.python.executable} ${files}/hello_world.py";
  };

  helloWorldTask = aurora.Task {
    processes = [ helloWorldProcess ];
    resources = {
      cpu = 1;
      ram = 1 * aurora.utils.MB;
      disk = 8 * aurora.utils.MB;
    };
  };

in aurora.Service {
  cluster = "devcluster";
  environment = "devel";
  role = "vagrant";
  task = helloWorldTask;
}
