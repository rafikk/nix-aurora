{ pkgs }:

rec {

  Job =
    { name ? task.name
    , task
    , cluster
    , environment
    , role
    , update_config
    , instances ? 1
    , production ? false
    , service ? false
    } @ attrs:

    let
      fullAttrs = { inherit name; } // attrs;
      sandbox = _sandbox fullAttrs;
      config = _config fullAttrs;

    in pkgs.stdenv.mkDerivation {
      name = "aurora-job-${cluster}-${role}-${environment}-${name}";
      propagatedBuildInputs = [ config sandbox ];
      buildCommand = ''
        mkdir -p $out
        ln -s ${sandbox} $out/sandbox
        ln -s ${config}/config.json $out/config.json
      '';
    };

  _config = attrs:
    pkgs.writeTextFile {
      name = with attrs; "aurora-config-${cluster}-${role}-${environment}-${name}";
      text = builtins.toJSON attrs;
      destination = "/config.json";
    };

  _sandbox = attrs: with attrs;
    pkgs.stdenv.mkDerivation {
      name = with attrs; "aurora-sandbox-${cluster}-${role}-${environment}-${name}";
      buildCommand = ''
        mkdir -p $out
        ln -s ${builtins.head task.raw_processes} $out/${(builtins.head task.processes).name}
      '';
    };

  Task =
    { name ? (builtins.head processes).name
    , processes
    , resources
    , constraints
    } @ attrs:
    {
      inherit name resources constraints;
      raw_processes = processes;
      processes = map
        (p: rec { inherit (p) name; cmdline = "exec ${name}"; })
        processes;
    };

  UpdateConfig =
    { batch_size, watch_secs, max_total_failures } @ attrs: attrs;

  Process =
    { name, cmdline, ... } @ attrs:
    pkgs.writeTextFile {
      inherit name;
      executable = true;
      text = cmdline;
    } // attrs;

  Resources =
    { cpu, ram, disk } @ attrs: attrs;

  utils = rec {
    B = 1;
    KB = 1024 * B;
    MB = 1024 * KB;
    GB = 1024 * MB;
  };

}
