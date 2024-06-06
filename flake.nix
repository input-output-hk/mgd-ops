{
  description = "Cardano Performance Testing Cluster";

  inputs = {
    auth-keys-hub.url = "github:input-output-hk/auth-keys-hub";
    auth-keys-hub.inputs.nixpkgs.follows = "nixpkgs";
    colmena.url = "github:zhaofengli/colmena/v0.4.0";
    colmena.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-24-05.url = "github:nixos/nixpkgs/nixos-24.05";
    sops-nix.url = "github:Mic92/sops-nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    terranix.url = "github:terranix/terranix";
    opentofu-registry.url = "github:opentofu/registry-stable";
    opentofu-registry.flake = false;
    cardano-db-sync-service = {
      url = "github:IntersectMBO/cardano-db-sync/sancho-4-3-0";
      flake = false;
    };
    capkgs.url = "github:input-output-hk/capkgs";
    iohk-nix.url = "github:input-output-hk/iohk-nix";
    cardano-node = {
      url = "github:IntersectMBO/cardano-node/8.11.0-pre";
      flake = false;
    };
    mgdoc-claim-enablement = {
      url = "git+ssh://git@github.com/input-output-hk/mgdoc-claim-enablement.git";
      flake = false;
    };
  };

  outputs = inputs: let
    inherit ((import ./flake/lib.nix {inherit inputs;}).flake.lib) recursiveImports;
  in
    inputs.flake-parts.lib.mkFlake {inherit inputs;}
    {
      systems = ["x86_64-linux"];
      imports = recursiveImports [./flake ./perSystem];
    };

  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
      "https://colmena.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
    ];
    allow-import-from-derivation = "true";
  };
}
