let
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-20.09.tar.gz";
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
