{
  perSystem = {
    system,
    lib,
    pkgs,
    config,
    inputs',
    self',
    ...
  }: {
    devShells.default = pkgs.mkShell {
      packages =
        (with pkgs; [
          just
          age
          statix
          wireguard-tools
          nushell
          self'.packages.rain
          self'.packages.terraform
          awscli2
          sops
        ])
        ++ (with inputs'; [
          colmena.packages.colmena
        ]);

      shellHook = let
        pre-push = pkgs.writeShellApplication {
          name = "pre-push";
          text = ''
            tput bold # bold
            tput setaf 5 # magenta
            echo >&2 'To skip, run git push with --no-verify.'
            tput sgr0 # reset

            declare -a checks
            for check in ${lib.escapeShellArgs (builtins.attrNames config.checks)}; do
              checks+=(.#checks.${lib.escapeShellArg system}."$check")
            done

            set -x
            nix build "''${checks[@]}"
          '';
        };
      in ''
        ln -sf ${lib.getExe pre-push} .git/hooks/
        ln -sf ${config.treefmt.build.configFile} treefmt.toml
      '';
      # ln -sf ${config.packages.ssh_config} .ssh_config

      # SSH_CONFIG_FILE = config.packages.ssh_config;

      RULES = "secrets/secrets.nix";
    };
  };
}
