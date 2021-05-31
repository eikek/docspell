let
  nixpkgs = builtins.fetchTarball {
    ## need fix to zola-0.11.0 for now
    url = "https://github.com/NixOS/nixpkgs/archive/92e990a8d6bc35f1089c76dd8ba68b78da90da59.tar.gz";
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
