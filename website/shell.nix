let
    nixpkgsUnstable = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz";
  };
  pkgsUnstable = import nixpkgsUnstable { };
in
with pkgsUnstable;

 mkShell {
   buildInputs = [
     zola
     yarn
     inotifyTools
  ];
 }
