{ config, pkgs, ... }:
let
  docspell = import ./release.nix;
in
{
  imports = docspell.modules;

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };
  console.keyMap = "neo";

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
    bind.address = "0.0.0.0";
    base-url = "http://localhost:7878";
  };
  services.docspell-restserver = {
    bind.address = "0.0.0.0";
    enable = true;
  };
  services.docspell-consumedir = {
    enable = true;
    watchDirs = ["/tmp/test"];
    urls = ["http://localhost:7880/api/v1/open/upload/item/blabla"];
  };

  environment.systemPackages =
    [ pkgs.docspell.tools
      pkgs.docspell.server
      pkgs.docspell.joex pkgs.jq
    ];

  services.xserver = {
    enable = false;
  };

  networking = {
    hostName = "docspelltest";
    firewall.allowedTCPPorts = [7880];
  };

  system.stateVersion = "20.03";

}
