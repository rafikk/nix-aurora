{ nixpkgs ? <nixpkgs> }:

let

  pkgs = import nixpkgs {};

  aurora = import ../../lib/aurora.nix { inherit pkgs; };

  prometheusProcess = aurora.Process {
    name = "prometheus";
    cmdline = ''
      ${pkgs.prometheus}/bin/prometheus \
        -config.file=${aurora.utils.files.copiedExpandedFile ./files/prometheus.yml} \
        -web.listen-address=0.0.0.0:{{thermos.ports[http]}} \
        -log.level=debug
      '';
  };

  prometheusTask = aurora.Task {
    processes = [
      prometheusProcess
    ];
    resources = {
      cpu = 1;
      ram = 8 * aurora.utils.MB;
      disk = 1 * aurora.utils.GB;
    };
  };

in aurora.Service {
  cluster = "devcluster";
  environment = "devel";
  role = "vagrant";
  task = prometheusTask;
}
