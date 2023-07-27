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

cf STACKNAME:
  mkdir cloudFormation
  nix eval --json ".#cloudFormation.{{STACKNAME}}" | jq | save -f "cloudFormation/{{STACKNAME}}.json"
  rain deploy -y ./cloudFormation/{{STACKNAME}}.json

c1:
  just cf ci1
