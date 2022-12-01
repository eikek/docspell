{ config, pkgs, ... }:
let
  full-text-search = {
    enabled = true;
    solr.url = "http://localhost:${toString config.services.solr.port}/solr/docspell";
    postgresql = {
      pg-config = {
        "german" = "my-germam";
      };
    };
  };
in
{

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };
  console.keyMap = "de";

  users.users.root = {
    password = "root";
  };


  services.docspell-joex = {
    enable = true;
    waitForTarget = "solr-init.target";
    bind.address = "0.0.0.0";
    base-url = "http://localhost:7878";
    jvmArgs = [ "-J-Xmx1536M" ];
    inherit full-text-search;
  };
  services.docspell-restserver = {
    enable = true;
    bind.address = "0.0.0.0";
    backend = {
      addons.enabled = true;
    };
    integration-endpoint = {
      enabled = true;
      http-header = {
        enabled = true;
        header-value = "test123";
      };
    };
    openid = [
      {
        enabled = true;
        display = "Local";
        provider = {
          provider-id = "local";
          client-id = "cid1";
          client-secret = "csecret-1";
          authorize-url = "http://auth";
          token-url = "http://token";
          sign-key = "b64:uiaeuae";
        };
      }
    ];
    inherit full-text-search;
  };

  environment.systemPackages =
    [
      pkgs.jq
      pkgs.inetutils
      pkgs.htop
      pkgs.openjdk
    ];


  services.xserver = {
    enable = false;
  };

  networking = {
    hostName = "docspelltest";
    firewall.allowedTCPPorts = [ 7880 ];
  };

  system.stateVersion = "22.05";

}
