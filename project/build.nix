with import <nixpkgs> { };
let
  initScript = writeScript "docspell-build-init" ''
     export LD_LIBRARY_PATH=
     ${bash}/bin/bash -c sbt
  '';
in
buildFHSUserEnv {
  name = "docspell-sbt";
  targetPkgs = pkgs: with pkgs; [
    netcat jdk8 wget which zsh dpkg sbt git elmPackages.elm ncurses fakeroot mc jekyll
    zola yarn

    # haskells http client needs this (to download elm packages)
    iana-etc
  ];
  runScript = initScript;
}
