{self, ...}: {
  perSystem = {pkgs, ...}: {
    checks.lint =
      pkgs.runCommand "lint" {
        nativeBuildInputs = with pkgs; [
          just
          nushell
          statix
          deadnix
        ];
      } ''
        set -euo pipefail

        cd ${self}
        just lint
        touch $out
      '';
  };
}
