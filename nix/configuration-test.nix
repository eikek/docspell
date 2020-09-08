{ config, pkgs, ... }:
let
  docspell = import ./release.nix;
  full-text-search = {
    enabled = true;
    solr.url = "http://localhost:${toString config.services.solr.port}/solr/docspell";
  };
in
{
  imports = docspell.modules ++ [ ./solr.nix ];

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
    waitForTarget = "solr-init.target";
    bind.address = "0.0.0.0";
    base-url = "http://localhost:7878";
    jvmArgs = [ "-J-Xmx2g" ];
    inherit full-text-search;
  };
  services.docspell-restserver = {
    enable = true;
    bind.address = "0.0.0.0";
    integration-endpoint = {
      enabled = true;
      http-header = {
        enabled = true;
        header-value = "test123";
      };
    };
    inherit full-text-search;
  };
  services.docspell-consumedir = {
    enable = true;
    integration-endpoint = {
      enabled = true;
      header = "Docspell-Integration:test123";
    };
    watchDirs = ["/tmp/docs"];
    urls = ["http://localhost:7880/api/v1/open/integration/item"];
  };

  environment.systemPackages =
    [ pkgs.docspell.tools
      pkgs.docspell.server
      pkgs.docspell.joex
      pkgs.jq
      pkgs.telnet
      pkgs.htop
      pkgs.openjdk
    ];


  services.xserver = {
    enable = false;
  };

  networking = {
    hostName = "docspelltest";
    firewall.allowedTCPPorts = [7880];
  };

  system.activationScripts = {
    initUploadDir = ''
      mkdir -p ${builtins.concatStringsSep " " config.services.docspell-consumedir.watchDirs}
    '';
  };
  system.stateVersion = "20.03";

}
