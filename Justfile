set shell := ["nu", "-c"]
set positional-arguments

default:
  just --list

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
  nix eval --json ".#cloudFormation.{{STACKNAME}}" | jq | save --force "cloudFormation/{{STACKNAME}}.json"
  rain deploy --termination-protection --yes ./cloudFormation/{{STACKNAME}}.json

c1:
  just cf ci1
