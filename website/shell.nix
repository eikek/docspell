let
  nixpkgsUnstable = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs-channels/archive/92e990a8d6bc35f1089c76dd8ba68b78da90da59.tar.gz";
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
