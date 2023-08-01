{inputs, ...}: {
  flake.cloudFormation = {
    terraformState = import ./terraformState.nix {};
  };
}
