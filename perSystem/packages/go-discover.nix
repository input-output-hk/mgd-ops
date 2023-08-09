{
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.go-discover = pkgs.buildGoModule rec {
      pname = "go-discover";
      version = "unstable";

      src = pkgs.fetchFromGitHub {
        owner = "hashicorp";
        repo = pname;
        rev = "e89ebd1b2f65c80bb2dd21570c12a2957c9aad82";
        sha256 = "sha256-VYoQz0mH4s4EB10CsgXDG+rSj3HcqbNYKuOvb0AMb5Q=";
      };

      vendorSha256 = "sha256-KYFbuhx49olmTYQtIdlLN8VsMEQPVts+UW9jBlkAiN8=";

      subPackages = ["cmd/discover"];

      meta = {
        description = "Discover nodes in cloud environments";
        homepage = "https://github.com/hashicorp/go-discover";
        license = lib.licenses.mpl20;
      };
    };
  };
}
