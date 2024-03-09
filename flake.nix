{
  description = "Docspell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    devshell-tools.url = "github:eikek/devshell-tools";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    devshell-tools,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      sbt17 = pkgs.sbt.override { jre = pkgs.jdk17; };
      devshellPkgs = with pkgs; [
        jq
        scala-cli
        sbt17

        netcat
        jdk17
        wget
        which
        dpkg
        elmPackages.elm
        fakeroot
        zola
        yarn
      ];
      docspellPkgs = pkgs.callPackage (import ./nix/pkg.nix) {};
      dockerAmd64 = pkgs.pkgsCross.gnu64.callPackage (import ./nix/docker.nix) {
        inherit (docspellPkgs) docspell-server docspell-joex;
      };
      dockerArm64 = pkgs.pkgsCross.aarch64-multiplatform.callPackage (import ./nix/docker.nix) {
        inherit (docspellPkgs) docspell-server docspell-joex;
      };
    in {
      formatter = pkgs.alejandra;

      packages = {
        inherit (docspellPkgs) docspell-server docspell-joex;
      };

      legacyPackages = {
        docker = {
          amd64 = {
            inherit (dockerAmd64) docspell-server docspell-joex;
          };
          arm64 = {
            inherit (dockerArm64) docspell-server docspell-joex;
          };
        };
      };

      checks = {
        build-server = self.packages.${system}.docspell-server;
        build-joex = self.packages.${system}.docspell-joex;

        test = with import (nixpkgs + "/nixos/lib/testing-python.nix")
        {
          inherit system;
        };
          makeTest {
            name = "docspell";
            nodes = {
              machine = {...}: {
                nixpkgs.overlays = [self.overlays.default];
                imports = [
                  self.nixosModules.default
                  ./nix/checks
                ];
              };
            };

            testScript = builtins.readFile ./nix/checks/testScript.py;
          };
      };

      devShells = {
        dev-cnt = pkgs.mkShellNoCC {
          buildInputs =
            (builtins.attrValues devshell-tools.legacyPackages.${system}.cnt-scripts)
            ++ devshellPkgs;

          DOCSPELL_ENV = "dev";
          DEV_CONTAINER = "docsp-dev";
          SBT_OPTS = "-Xmx2G -Xss4m";
        };
        dev-vm = pkgs.mkShellNoCC {
          buildInputs =
            (builtins.attrValues devshell-tools.legacyPackages.${system}.vm-scripts)
            ++ devshellPkgs;

          DOCSPELL_ENV = "dev";
          SBT_OPTS = "-Xmx2G -Xss4m";
          DEV_VM = "dev-vm";
          VM_SSH_PORT = "10022";
        };
      };
    })
    // {
      nixosModules = {
        default = {...}: {
          imports = [
            ./nix/modules/server.nix
            ./nix/modules/joex.nix
          ];
        };
        server = import ./nix/modules/server.nix;
        joex = import ./nix/modules/joex.nix;
      };

      overlays.default = final: prev: let
        docspellPkgs = final.callPackage (import ./nix/pkg.nix) {};
      in {
        inherit (docspellPkgs) docspell-server docspell-joex;
      };

      nixosConfigurations = {
        test-vm = devshell-tools.lib.mkVm {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.default
            {
              nixpkgs.overlays = [self.overlays.default];
            }
            ./nix/test-vm.nix
          ];
        };
        docsp-dev = devshell-tools.lib.mkContainer {
          system = "x86_64-linux";
          modules = [
            {
              services.dev-postgres = {
                enable = true;
                databases = ["docspell"];
              };
              services.dev-email.enable = true;
              services.dev-minio.enable = true;
              services.dev-solr = {
                enable = true;
                cores = ["docspell"];
              };
            }
          ];
        };
        dev-vm = devshell-tools.lib.mkVm {
          system = "x86_64-linux";
          modules = [
            {
              services.dev-postgres = {
                enable = true;
                databases = ["docspell"];
              };
              services.dev-email.enable = true;
              services.dev-minio.enable = true;
              services.dev-solr = {
                enable = true;
                cores = ["docspell"];
              };

              port-forward.ssh = 10022;
              port-forward.dev-postgres = 6534;
              port-forward.dev-smtp = 10025;
              port-forward.dev-imap = 10143;
              port-forward.dev-webmail = 8080;
              port-forward.dev-minio-api = 9000;
              port-forward.dev-minio-console = 9001;
              port-forward.dev-solr = 8983;
              networking.hostName = "dev-vm";
            }
          ];
        };
      };
    };
}
