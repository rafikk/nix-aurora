{ pkgs }:

rec {

  Job =
    { name ? task.name
    , role
    , contact ? null
    , cluster
    , environment
    , instances ? 1
    , task
    , announce ? null
    , cron_schedule ? null
    , cron_collision_policy ? "KILL_EXISTING"
    , constraints ? null
    , service ? false
    , update_config ? UpdateConfig {}
    , max_task_failures ? 1
    , production ? false
    , priority ? 0
    , health_check_config ? HealthCheckConfig {}
    , enable_hooks ? false
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

  Process =
    { cmdline
    , name
    , max_failures ? 1
    , daemon ? false
    , ephemeral ? false
    , final ? false
    , min_duration ? 5
    , propagatedBuildInputs ? []
    , buildInputs ? []
    } @ attrs:
    pkgs.writeTextFile {
      inherit name;
      executable = true;
      text = cmdline;
    } // attrs;

  Resources =
    { cpu
    , ram
    , disk
    } @ attrs: attrs;

  UpdateConfig =
    { batch_size ? 1
    , restart_threshold ? 60
    , watch_secs ? 45
    , max_per_shard_failures ? 0
    , max_total_failures ? 0
    , rollback_on_failure ? true
    , wait_for_batch_completion ? false
    , pulse_interval_secs ? null
    } @ attrs: attrs;

  HealthCheckConfig =
    { initial_interval_secs ? 15
    , interval_secs ? 10
    , timeout_secs ? 1
    , max_consecutive_failures ? 0
    , endpoint ? "/health"
    , expected_response ? "ok"
    , expected_response_code ? 0
    } @ attrs: attrs;

  Announcer =
    { primary_port ? "http"
    , port_map ? { aurora = "{{primary_port}}"; }
    } @ attrs: attrs;

  utils = rec {
    B = 1;
    KB = 1024 * B;
    MB = 1024 * KB;
    GB = 1024 * MB;
  };

}
