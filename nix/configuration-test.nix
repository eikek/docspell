{ config, pkgs, ... }:
let
  docspell = import ./release.nix;
in
{
  imports = docspell.modules;

  i18n = {
    consoleKeyMap = "neo";
    defaultLocale = "en_US.UTF-8";
  };

  users.users.root = {
    password = "root";
  };

  nixpkgs = {
    config = {
      packageOverrides = pkgs:
        let
          callPackage = pkgs.lib.callPackageWith(custom // pkgs);
          custom = {
            docspell = callPackage docspell.currentPkg {};
          };
        in custom;
    };
  };

  services.docspell-joex = {
    enable = true;
    base-url = "http://docspelltest:7878";
  };
  services.docspell-restserver = {
    enable = true;
  };
  services.docspell-consumedir = {
    enable = true;
    watchDirs = ["/tmp/test"];
    urls = ["http://localhost:7880/api/v1/open/upload/item/blabla"];
  };

  environment.systemPackages = [ pkgs.docspell.tools pkgs.jq ];

  services.xserver = {
    enable = false;
  };

  networking = {
    hostName = "docspelltest";
  };

  system.stateVersion = "19.09";

}
