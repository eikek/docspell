{
  description = "Docspell flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
      # Version config
      cfg = {
        v0_39_0 = rec {
          version = "0.39.0";
          server = {
            url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-restserver-${version}.zip";
            sha256 = "sha256-YZzYOqJzp2J5ioTT8H7qpRA3mHDRjJYNA7fUOEQWSfY=";
          };
          joex = {
            url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-joex-${version}.zip";
            sha256 = "sha256-6Vcuk9+JDkNAdTQd+sRLARfE+y9cbtGE8hWTTcxZk3E=";
          };
        };
      };
      current_version = cfg.v0_39_0;
      inherit (current_version) version;
    in
    rec
    {
      overlays.default = final: prev: {
        docspell-server = with final; stdenv.mkDerivation {
          inherit version;
          pname = "docspell-server";

          src = fetchzip current_version.server;
          buildInputs = [ jdk11 ];
          buildPhase = "true";

          installPhase = ''
            mkdir -p $out/{bin,docspell-restserver-${version}}
            cp -R * $out/docspell-restserver-${version}/
            cat > $out/bin/docspell-restserver <<-EOF
            #!${bash}/bin/bash
            $out/docspell-restserver-${version}/bin/docspell-restserver -java-home ${jdk11} "\$@"
            EOF
            chmod 755 $out/bin/docspell-restserver
          '';
        };
        docspell-joex = with final; stdenv.mkDerivation rec {
          inherit version;

          pname = "docspell-joex";

          src = fetchzip current_version.joex;

          buildInputs = [ jdk11 ];

          buildPhase = "true";

          installPhase = ''
            mkdir -p $out/{bin,docspell-joex-${version}}
            cp -R * $out/docspell-joex-${version}/
            cat > $out/bin/docspell-joex <<-EOF
            #!${bash}/bin/bash
            $out/docspell-joex-${version}/bin/docspell-joex -java-home ${jdk11} "\$@"
            EOF
            chmod 755 $out/bin/docspell-joex
          '';
        };

      };

      packages = forAllSystems (system:
        {
          default = (import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          }).docspell-server;
        });

      checks = forAllSystems
        (system: {
          build = self.packages.${system}.default;

          test =
            with import (nixpkgs + "/nixos/lib/testing-python.nix")
              {
                inherit system;
              };

            makeTest {
              name = "docspell";
              nodes = {
                machine = { ... }: {
                  imports = [
                    self.nixosModules.default
                    ./checks
                  ];
                };
              };

              testScript = builtins.readFile ./checks/testScript.py;
            };
        });

      nixosModules = {
        default = { ... }: {
          imports = [
            ((import ./modules/server.nix) self.overlays.default)
            ((import ./modules/joex.nix) self.overlays.default)
          ];
        };
        server = ((import ./modules/server.nix) self.overlays.default);
        joex = ((import ./modules/joex.nix) self.overlays.default);
      };

    };
}
