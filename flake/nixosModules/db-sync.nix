{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.db-sync = {
    lib,
    pkgs,
    config,
    ...
  }: let
    system = "x86_64-linux";
    nodeVersion = "8-11-0-pre-38c7f1c";
    dbSyncVersion = "sancho-4-3-0-56c6b15";

    cardano-db-tool = inputs.capkgs.packages.${system}."\"cardano-db-tool:exe:cardano-db-tool\"-input-output-hk-cardano-db-sync-${dbSyncVersion}";
    cardano-db-sync = inputs.capkgs.packages.${system}."\"cardano-db-sync:exe:cardano-db-sync\"-input-output-hk-cardano-db-sync-${dbSyncVersion}";
    cardano-node = inputs.capkgs.packages.x86_64-linux."cardano-node-input-output-hk-cardano-node-${nodeVersion}";

    removeByPath = pathList:
      lib.updateManyAttrsByPath [
        {
          path = lib.init pathList;
          update = lib.filterAttrs (n: _: n != (lib.last pathList));
        }
      ];

    mkCardanoLib = system: flakeRef:
    # Remove the dead testnet environment until it is removed from iohk-nix
      removeByPath ["environments" "testnet"]
      (import inputs.nixpkgs {
        inherit system;
        overlays = map (
          overlay: flakeRef.overlays.${overlay}
        ) (builtins.attrNames flakeRef.overlays);
      })
      .cardanoLib;

    cardanoLib = mkCardanoLib system inputs.iohk-nix;
  in let
    # inherit (perNodeCfg.pkgs) cardano-db-sync cardano-db-sync-pkgs cardano-db-tool;
    cardano-db-sync-pkgs = {
      cardanoDbSyncHaskellPackages.cardano-db-tool.components.exes.cardano-db-tool =
        cardano-db-tool;
      inherit cardanoLib;
      schema = "${inputs.cardano-db-sync-service}/schema";
    };

    inherit (cardanoLib) environments;
    environmentName = "sanchonet";
    environmentConfig = environments.${environmentName};
  in {
    aws.instance.tags.Role = "db-sync";

    imports = [
      "${inputs.cardano-node}/nix/nixos"
      "${inputs.cardano-db-sync-service}/nix/nixos"
      self.nixosModules.postgrest
    ];

    environment.systemPackages =
      [
        cardano-db-tool
        cardano-node
        inputs.capkgs.packages.x86_64-linux."db-analyser-input-output-hk-cardano-node-${nodeVersion}"
        inputs.capkgs.packages.x86_64-linux."db-synthesizer-input-output-hk-cardano-node-${nodeVersion}"
        inputs.capkgs.packages.x86_64-linux."db-truncater-input-output-hk-cardano-node-${nodeVersion}"
      ]
      ++ (with pkgs; [
        screen
        sqlite-interactive
        tmux
        gnupg
        pinentry
        zellij
      ]);

    sops.secrets = let
      mkSecret = name: {
        sopsFile = "${self}/secrets/node-spo1/${name}.enc";
        restartUnits = ["cardano-node.service"];
        owner = "cardano-node";
      };
    in {
      signingKey = mkSecret "byron-delegate.key";
      delegationCertificate = mkSecret "byron-delegation.cert";
      kesKey = mkSecret "kes.skey";
      vrfKey = mkSecret "vrf.skey";
      operationalCertificate = mkSecret "opcert.cert";
      skopeo = {
        sopsFile = ../../secrets/skopeo.enc;
        owner = "dev";
        group = "nixbld";
        mode = "0444";
      };
    };

    nix.settings.extra-sandbox-paths = [
      "/etc/skopeo/auth.json=${config.sops.secrets.skopeo.path}"
    ];

    services = {
      postgrest = {
        enable = true;
        dbuser = "cexplorer";
        dbname = "cexplorer";
      };

      cardano-node = {
        enable = true;
        environment = "perf";
        dbPrefix = "db-perf";
        package = cardano-node;
        hostAddr = "0.0.0.0";
        useSystemdReload = true;
        systemdSocketActivation = false;
        bootstrapPeers = null;
        # usePeersFromLedgerAfterSlot = null;
        useLegacyTracing = true;
        signingKey = config.sops.secrets.signingKey.path;
        delegationCertificate = config.sops.secrets.delegationCertificate.path;
        kesKey = config.sops.secrets.kesKey.path;
        vrfKey = config.sops.secrets.vrfKey.path;
        operationalCertificate = config.sops.secrets.operationalCertificate.path;

        environments.perf.nodeConfig =
          (builtins.fromJSON (
            lib.fileContents ./node/configuration.json
          ))
          // {
            ByronGenesisFile = ./node/genesis.byron.json;
            ShelleyGenesisFile = ./node/genesis.shelley.json;
            AlonzoGenesisFile = ./node/genesis.alonzo.json;
            ConwayGenesisFile = ./node/genesis.conway.json;
            SocketPath = config.services.cardano-node.socketPath 0;
          };

        producers = [];
      };

      postgresql = {
        enable = true;
        package = pkgs.postgresql_16;
        ensureDatabases = ["cexplorer"];
        ensureUsers = [
          {
            name = "cexplorer";
            ensureDBOwnership = true;
          }
        ];

        identMap = ''
            explorer-users postgres postgres
          ${lib.concatMapStrings (user: ''
            explorer-users ${user} cexplorer
          '') ["root" "cardano-db-sync"]}'';

        authentication = ''
          local all all ident map=explorer-users
        '';
      };

      # Profile cardano-postgres is tuned for 70% of RAM, leaving ~20% for node
      # and 10% for other services (dbsync smash) and overhead.
      # cardano-node.totalMaxHeapSizeMiB = 1024;
      # cardano-postgres.ramAvailableMiB = 2048;

      cardano-db-sync = {
        enable = true;
        package = cardano-db-sync;
        dbSyncPkgs = cardano-db-sync-pkgs;

        cluster = "perf";
        environment = {
          inherit (config.services.cardano-node.environments.perf) nodeConfig;
          dbSyncConfig =
            environmentConfig.dbSyncConfig
            // {
              NetworkName = "perf";
              NodeConfigFile = builtins.toFile "config.json" (
                builtins.toJSON
                config.services.cardano-node.environments.perf.nodeConfig
              );
            };
        };
        socketPath = config.services.cardano-node.socketPath 0;
        explorerConfig = config.services.cardano-db-sync.environment.dbSyncConfig // {PrometheusPort = 8302;};
        logConfig = {};
        postgres.database = "cexplorer";
      };
    };

    systemd.services.cardano-node = {
      after = ["sops-nix.service"];
      serviceConfig.SupplementaryGroups = [config.users.groups.keys.name];
      postStart = ''
        path="${config.services.cardano-node.socketPath 0}"
        while test ! -S $path; do
          sleep 1
        done

        chmod g+w $path
      '';
    };

    systemd.services.cardano-db-sync = {
      # Required by the cardano-db-sync restoreSnapshot and takeSnapshot scripts in ExecStopPost
      # Ref: https://github.com/IntersectMBO/cardano-db-sync/issues/1645

      path = with pkgs; [getconf tree];
      wantedBy = ["multi-user.target"];
      after = ["cardano-node.service"];
    };

    # Ensure access to the cardano-node socket
    users = {
      users = {
        dev = {
          isNormalUser = true;
          createHome = true;
        };
        cardano-db-sync = {
          extraGroups = ["cardano-node"];
          group = "cardano-db-sync";
          isSystemUser = true;
        };
      };

      groups.cardano-db-sync = {};
    };

    programs.auth-keys-hub.github = {
      users = [
        "dev:jhbertra"
      ];

      teams = [
        "input-output-hk/mgdoc"
      ];
    };

    networking.firewall.allowedTCPPorts = [5580];
  };
}
