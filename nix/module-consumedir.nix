{config, lib, pkgs, ...}:

with lib;
let
  cfg = config.services.docspell-consumedir;
  user = if cfg.runAs == null then "docspell-consumedir" else cfg.runAs;
in {

  ## interface
  options = {
    services.docspell-consumedir = {
      enable = mkOption {
        default = false;
        description = "Whether to enable docspell consume directory.";
      };

      runAs = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          The user that runs the consumedir process.
        '';
      };

      watchDirs = mkOption {
        type = types.listOf types.str;
        description = "The directories to watch for new files.";
      };

      verbose = mkOption {
        type = types.bool;
        default = false;
        description = "Run in verbose mode";
      };

      deleteFiles = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to delete successfully uploaded files.";
      };

      distinct = mkOption {
        type = types.bool;
        default = true;
        description = "Check for duplicates and update only if the file is not already present.";
      };

      integration-endpoint = mkOption {
        type = types.submodule({
          options = {
            enabled = mkOption {
              type = types.bool;
              default = false;
              description = "Whether to upload to the integration endpoint.";
            };
            header = mkOption {
              type = types.str;
              default = "";
              description = ''
                The `header:value` string matching the configured header-name
                 and value for the integration endpoint.
              '';
            };
            user = mkOption {
              type = types.str;
              default = "";
              description = ''
                The `user:password` string matching the configured user and password
                for the integration endpoint. Since both are separated by a colon, the
                user name may not contain a colon (the password can).
              '';
            };
          };
        });
        default = {
          enabled = false;
          header = "";
          user = "";
        };
        description = "Settings for using the integration endpoint.";
      };
      urls = mkOption {
        type = types.listOf types.str;
        example = [ "http://localhost:7880/api/v1/open/upload/item/abced-12345-abcde-12345" ];
        description = "A list of upload urls.";
      };
    };
  };

  ## implementation
  config = mkIf config.services.docspell-consumedir.enable {

    users.users."${user}" = mkIf (cfg.runAs == null) {
      name = user;
      isSystemUser = true;
      description = "Docspell consumedir user";
    };

    systemd.services.docspell-consumedir =
    let
      args = (builtins.concatMap (a: ["--path" ("'" + a + "'")]) cfg.watchDirs) ++
             (if cfg.verbose then ["-v"] else []) ++
             (if cfg.deleteFiles then ["-d"] else []) ++
             (if cfg.distinct then [ "-m" ] else []) ++
             (if cfg.integration-endpoint.enabled then [ "-i" ] else []) ++
             (if cfg.integration-endpoint.header != ""
              then
                [ "--iheader" cfg.integration-endpoint.header ]
              else
                []) ++
             (if cfg.integration-endpoint.user != ""
              then
                [ "--iuser" cfg.integration-endpoint.user ]
              else
                []) ++
             (map (a: "'" + a + "'") cfg.urls);
      cmd = "${pkgs.docspell.tools}/bin/consumedir.sh " + (builtins.concatStringsSep " " args);
    in
    {
      description = "Docspell Consumedir";
      after = [ "networking.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.utillinux pkgs.curl pkgs.coreutils ];

      script =
        "${pkgs.su}/bin/su -s ${pkgs.bash}/bin/sh ${user} -c \"${cmd}\"";
    };
  };
}
