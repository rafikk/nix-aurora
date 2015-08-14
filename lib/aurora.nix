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

      mkProcessDerivation = process: pkgs.writeTextFile {
        name = "aurora-process-${cluster}-${role}-${environment}-${name}-${process.name}";
        text = process.cmdline;
        executable = true;
      };

      mkInitProcess = process: {
        name = "nix_init_${process.name}";
        cmdline = ''
          . /home/vagrant/.nix-profile/etc/profile.d/nix.sh
          nix-store --add-root .gc/${process.name} --indirect -r ${mkProcessDerivation process}
        '';
      };

      initProcesses = map mkInitProcess task.processes;

      processes = initProcesses ++ task.processes;

      constraints = (map
        (p: { order = [ "nix_init_${p.name}" p.name ]; }) task.processes)
        ++ task.constraints;

      wrappedTask = task // { inherit processes constraints; };

    in pkgs.writeTextFile {
      name = with attrs; "aurora-job-${cluster}-${role}-${environment}-${name}";
      text = builtins.toJSON (attrs // { inherit name; task = wrappedTask; });
    };

  Service = attrs: Job (attrs // { service = true; });

  Task =
    { name ? (builtins.head processes).name
    , processes
    , constraints ? []
    , resources ? null
    , max_failures ? 1
    , max_concurrency ? 0
    , finalization_wait ? 30
    } @ attrs:
    { inherit name constraints; } // attrs;

  Process =
    { cmdline
    , name
    , max_failures ? 1
    , daemon ? false
    , ephemeral ? false
    , final ? false
    , min_duration ? 5
    } @ attrs: attrs;

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
