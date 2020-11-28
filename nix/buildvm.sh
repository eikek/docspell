#!/usr/bin/env bash

if [ "$1" = "-f" ]; then
    echo "Deleting current state image..."
    rm *.qcow2
fi

nixos-rebuild build-vm \
  -I nixos-config=./configuration-test.nix \
  -I nixpkgs=https://github.com/NixOS/nixpkgs-channels/archive/nixos-20.09.tar.gz
