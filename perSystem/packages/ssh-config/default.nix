{
  config,
  self,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages = let
      inherit (config.flake) nixosConfigurations;

      knownHosts = pkgs.writeText "known_hosts" (
        builtins.concatStringsSep "\n" (
          pkgs.lib.mapAttrsToList (
            nodeName: node: let
              host = node.config.deployment.targetHost;
              key = pkgs.lib.fileContents "${self}/flake/colmena/nodes/${nodeName}/ssh_host_ed25519_key.pub";
            in "${host} ${key}"
          )
          nixosConfigurations
        )
      );

      hostLines =
        pkgs.lib.mapAttrsToList (
          nodeName: node: ''
            Host ${nodeName}
              HostName ${node.config.deployment.targetHost}
          ''
        )
        nixosConfigurations;
    in {
      ssh_config = pkgs.writeText "ssh_config" ''
        Host *
          ServerAliveInterval 30
          ConnectTimeout 5
          ConnectionAttempts 2
          User root
          UserKnownHostsFile ${knownHosts}

        ${builtins.concatStringsSep "\n" hostLines}
      '';

      ssh_config_bootstrap = pkgs.writeText "ssh_config_bootstrap" ''
        Host *
          ServerAliveInterval 30
          ConnectTimeout 20
          ConnectionAttempts 5
          User root
          UserKnownHostsFile /dev/null
          StrictHostKeyChecking no

        ${builtins.concatStringsSep "\n" hostLines}
      '';
    };
  };
}
