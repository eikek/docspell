let
  nixpkgs = builtins.fetchTarball {
    #url = "channel:nixos-21.05";
    url = "https://github.com/NixOS/nixpkgs/archive/e6badb26fc0d238fda2432c45b7dd4e782eb8200.tar.gz";
  };
  pkgs = import nixpkgs { };
in
with pkgs;

 mkShell {
   buildInputs = [
     zola
     yarn
     inotifyTools
  ];
 }
