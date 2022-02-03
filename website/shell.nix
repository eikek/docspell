let
  nixpkgs = builtins.fetchTarball {
    #url = "channel:nixos-21.11";
    #url = "https://github.com/NixOS/nixpkgs/archive/e6badb26fc0d238fda2432c45b7dd4e782eb8200.tar.gz";
    url = "https://github.com/NixOs/nixpkgs/archive/0f316e4d72daed659233817ffe52bf08e081b5de.tar.gz"; #21.11
  };
  pkgs = import nixpkgs { };
in
with pkgs;

 mkShell {
   buildInputs = [
     zola
     yarn
     sbt
     elmPackages.elm
     nodejs
     inotifyTools
  ];
 }
