let
  staff = {
    michael = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJQnxCAgDAucoHZauKVR5BiSqL7zRFin/JPurBULETDl";
    robin = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCu2OiuMR/T7lMWjlsBkF0yFKv0puqFctuHXmfMLaZeUU7ACkGwKnhY55pnEaWiSDiqjf1VsB7WvkW9Js/nF+cP2hVtwiHoVDJQeCv0v+b1vPNfhxTaEAk9+U82G3C5tD8Rzi7H2NNEv7MlEeqfdP5a4UKOMW+XTJT5XolwQvIFuYKz4sLl28uDBmHtz+WqQeHgthkldWrEAvVoGDq0qzfBhhAlC0xsghYGAWYAlIOtj0MrJoBWtQoqqEkO9+hXUAwUixMy8JUmSStzEblgXr8OMKaPiKKX7tyYencZp6PG8gva8HUd3drI6Kb+5NXBq5N2PAnWI12osuwXuntiUNQF";
  };

  nodes = let
    nodesDir = ../flake/colmena/nodes;
  in
    with builtins;
      listToAttrs (
        map (name: {
          inherit name;
          value = readFile "${nodesDir}/${name}/ssh_host_ed25519_key.pub";
        }) (attrNames (readDir nodesDir))
      );
in
