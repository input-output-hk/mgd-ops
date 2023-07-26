set shell := ["nu", "-c"]
set positional-arguments

apply-all:
  colmena apply --verbose

apply *ARGS:
  colmena apply --verbose --on {{ARGS}}

ssh HOSTNAME *ARGS:
 ssh -F $env.SSH_CONFIG_FILE {{HOSTNAME}} {{ARGS}}

bootstrap HOSTNAME:
  nix run ".#bootstrap" -- --verbose --flake ".#{{HOSTNAME}}"

gen-wg:
  #!/usr/bin/env nu
  (colmena eval -E 'n: builtins.attrNames n.nodes' | from json) | each {|n|
    let private_path = $"secrets/nodes/($n)/wg_priv.age"
    let public_path = $"flake/colmena/nodes/($n)/wg_pub.key"

    if ($public_path | path exists) {} else {
      let private = (wg genkey)
      $private | agenix --editor - -e $private_path
      $private | wg pubkey | save $public_path 
    }
  }

cf HOSTNAME:
  mkdir cloudFormation
  nix eval --json ".#cloudFormation.{{HOSTNAME}}" | jq | save -f "cloudFormation/{{HOSTNAME}}.json"
  rain deploy -y ./cloudFormation/{{HOSTNAME}}.json

c1:
  just cf ci1
