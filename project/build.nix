let
    nixpkgsUnstable = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz";
  };
  pkgsUnstable = import nixpkgsUnstable { };
  initScript = pkgsUnstable.writeScript "docspell-build-init" ''
     export LD_LIBRARY_PATH=
     ${pkgsUnstable.bash}/bin/bash -c sbt
  '';
in with pkgsUnstable;

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
