let
  nixpkgs = builtins.fetchTarball {
    ## need fix to zola-0.11.0 for now
    url = "https://github.com/NixOS/nixpkgs/archive/92e990a8d6bc35f1089c76dd8ba68b78da90da59.tar.gz";
  };
  pkgs = import nixpkgs { };
  initScript = pkgs.writeScript "docspell-build-init" ''
     export LD_LIBRARY_PATH=
     ${pkgs.bash}/bin/bash -c "sbt -mem 2048 -java-home ${pkgs.openjdk11}/lib/openjdk"
  '';
in with pkgs;

buildFHSUserEnv {
  name = "docspell-sbt";
  targetPkgs = pkgs: with pkgs; [
    netcat jdk8 wget which zsh dpkg sbt git elmPackages.elm ncurses fakeroot mc
    zola yarn

    # haskells http client needs this (to download elm packages)
    iana-etc
  ];
  runScript = initScript;
}
