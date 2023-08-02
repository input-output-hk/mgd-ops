{
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.nomad = pkgs.buildGoModule rec {
      pname = "nomad";
      version = "1.6.1";

      subPackages = ["."];

      src = pkgs.fetchFromGitHub {
        owner = "hashicorp";
        repo = pname;
        rev = "release/${version}";
        sha256 = "sha256-lBEpZdho896Nulro/d2z4KAVAt2lZZqmlcAxIOkR0MA=";
      };

      vendorSha256 = "sha256-Y3O7ADzZPlLWFbXSYBcI6b5MAhMD0UnkhQxO9VJMpOY=";

      patches = [
        ./nomad-exec-nix-driver.patch
      ];

      nativeBuildInputs = [pkgs.installShellFiles];

      # ui:
      #  Nomad release commits include the compiled version of the UI, but the file
      #  is only included if we build with the ui tag.
      tags = ["ui"];

      passthru.tests.nomad = pkgs.nixosTests.nomad;

      postInstall = ''
        echo "complete -C $out/bin/nomad nomad" > nomad.bash
        installShellCompletion nomad.bash
      '';

      preCheck = ''
        export PATH="$PATH:/build/go/bin"
      '';

      meta = with lib; {
        homepage = "https://www.nomadproject.io/";
        description = "A Distributed, Highly Available, Datacenter-Aware Scheduler";
        platforms = platforms.unix;
        license = licenses.mpl20;
        maintainers = with maintainers; [rushmorem pradeepchhetri endocrimes maxeaubrey techknowlogick];
      };
    };
  };
}
