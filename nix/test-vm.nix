{
  config,
  pkgs,
  ...
}: let
  full-text-search = {
    enabled = true;
    backend = "solr";
    solr.url = "http://localhost:8983/solr/docspell";
  };
  jdbc = {
    url = "jdbc:postgresql://localhost:5432/docspell";
    user = "dev";
    password = "dev";
  };
in {
  services.dev-postgres = {
    enable = true;
    databases = ["docspell"];
  };
  services.dev-email.enable = true;
  services.dev-solr = {
    enable = true;
    cores = ["docspell"];
    heap = 512;
  };

  port-forward.dev-webmail = 8080;
  port-forward.dev-solr = 8983;

  environment.systemPackages = with pkgs; [
    jq
    htop
    iotop
    coreutils
  ];

  networking = {
    hostName = "docspell-test-vm";
    firewall.allowedTCPPorts = [7880];
  };

  virtualisation.memorySize = 2048;
  virtualisation.cores = 2;

  virtualisation.forwardPorts = [
    {
      from = "host";
      host.port = 7881;
      guest.port = 7880;
    }
  ];

  services.docspell-restserver = {
    enable = true;
    bind.address = "0.0.0.0";
    backend = {
      addons.enabled = true;
      signup.mode = "open";
      inherit jdbc;
    };
    integration-endpoint = {
      enabled = true;
      http-header = {
        enabled = true;
        header-value = "test123";
      };
    };
    admin-endpoint = {
      secret = "admin123";
    };
    inherit full-text-search;
  };

  services.docspell-joex = {
    enable = true;
    bind.address = "0.0.0.0";
    inherit jdbc full-text-search;
    addons = {
      executor-config = {
        runner = "nix-flake,trivial";
        nspawn.enabled = true;
      };
    };
  };
}
