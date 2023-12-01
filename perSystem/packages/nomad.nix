{
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.nomad = pkgs.buildGoModule rec {
      pname = "nomad";
      version = "1.6.3";

      subPackages = ["."];

      src = pkgs.fetchFromGitHub {
        owner = "hashicorp";
        repo = pname;
        rev = "release/${version}";
        sha256 = "sha256-yOlR8lka3TbCNo7N0xQNzrNe6H7t7EabR8oVevFSHd0=";
      };

      vendorHash = "sha256-gXoheW6Ww9Iu4utKNHweP2blzhWid+Q9Tp0ZgCmBAVg=";

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
