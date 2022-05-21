let
  nixpkgs = builtins.fetchTarball {
    #url = "https://github.com/NixOS/nixpkgs/archive/92e990a8d6bc35f1089c76dd8ba68b78da90da59.tar.gz";
    url =  "channel:nixos-21.11";
  };
  pkgs = import nixpkgs { };
  initScript = pkgs.writeScript "docspell-build-init" ''
     export LD_LIBRARY_PATH=
     ${pkgs.bash}/bin/bash -c "sbt -mem 4096 -java-home ${pkgs.openjdk11}/lib/openjdk"
  '';
in with pkgs;

buildFHSUserEnv {
  name = "docspell-sbt";
  targetPkgs = pkgs: with pkgs; [
    netcat jdk11 wget which dpkg sbt git elmPackages.elm ncurses fakeroot mc
    zola yarn

    # haskells http client needs this (to download elm packages)
    iana-etc
  ];
  runScript = initScript;
}
