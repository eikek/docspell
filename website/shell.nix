let
  nixpkgs = builtins.fetchTarball {
    #url = "channel:nixos-21.05";
    url = "https://github.com/NixOS/nixpkgs/archive/2d6ab6c6b92f7aaf8bc53baba9754b9bfdce56f2.tar.gz";
    #sha256 = "0l975q132x08qvw73qj391dl6qk9a661my8njcg5sl5rcmna3bmj";
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
