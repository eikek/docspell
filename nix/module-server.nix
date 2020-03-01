{config, lib, pkgs, ...}:

with lib;
let
  cfg = config.services.docspell-restserver;
  user = if cfg.runAs == null then "docspell" else cfg.runAs;
  configFile = pkgs.writeText "docspell-server.conf" ''
    {"docspell": {"server":
      ${builtins.toJSON cfg}
    }}
  '';
  defaults = {
    app-name = "Docspell";
    app-id = "rest1";
    base-url = "http://localhost:7880";
    bind = {
      address = "localhost";
      port = 7880;
    };
    auth = {
      server-secret = "hex:caffee";
      session-valid = "5 minutes";
    };
    backend = {
      jdbc = {
        url = "jdbc:h2:///tmp/docspell-demo.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE";
        user = "sa";
        password = "";
      };
      signup = {
        mode = "open";
        new-invite-password = "";
        invite-time = "3 days";
      };
      files = {
        chunk-size = 524288;
        valid-mime-types = [];
      };
    };
  };
in {

  ## interface
  options = {
    services.docspell-restserver = {
      enable = mkOption {
        default = false;
        description = "Whether to enable docspell.";
      };
      runAs = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Specify a user for running the application. If null, a new
          user is created.
        '';
      };

      app-name = mkOption {
        type = types.str;
        default = defaults.app-name;
        description = "The name used in the web ui and in notification mails.";
      };

      app-id = mkOption {
        type = types.str;
        default = defaults.app-id;
        description = ''
          This is the id of this node. If you run more than one server, you
          have to make sure to provide unique ids per node.
        '';
      };

      base-url = mkOption {
        type = types.str;
        default = defaults.base-url;
        description = ''
          This is the base URL this application is deployed to. This is used
          to create absolute URLs and to configure the cookie.
        '';
      };

      bind = mkOption {
        type = types.submodule({
          options = {
            address = mkOption {
              type = types.str;
              default = defaults.bind.address;
              description = "The address to bind the REST server to.";
            };
            port = mkOption {
              type = types.int;
              default = defaults.bind.port;
              description = "The port to bind the REST server";
            };
          };
        });
        default = defaults.bind;
        description = "Address and port bind the rest server.";
      };

      auth = mkOption {
        type = types.submodule({
          options = {
            server-secret = mkOption {
              type = types.str;
              default = defaults.auth.server-secret;
              description = ''
                The secret for this server that is used to sign the authenicator
                tokens. If multiple servers are running, all must share the same
                secret. You can use base64 or hex strings (prefix with b64: and
                hex:, respectively).
              '';
            };
            session-valid = mkOption {
              type = types.str;
              default = defaults.auth.session-valid;
              description = ''
                How long an authentication token is valid. The web application
                will get a new one periodically.
              '';
            };
          };
        });
        default = defaults.auth;
        description = "Authentication";
      };

      backend = mkOption {
        type = types.submodule({
          options = {
            jdbc = mkOption {
              type = types.submodule ({
                options = {
                  url = mkOption {
                    type = types.str;
                    default = defaults.backend.jdbc.url;
                    description = ''
                      The URL to the database. By default a file-based database is
                      used. It should also work with mariadb and postgresql.

                      Examples:
                         "jdbc:mariadb://192.168.1.172:3306/docspell"
                         "jdbc:postgresql://localhost:5432/docspell"
                         "jdbc:h2:///home/dbs/docspell.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE"

                    '';
                  };
                  user = mkOption {
                    type = types.str;
                    default = defaults.backend.jdbc.user;
                    description = "The user name to connect to the database.";
                  };
                  password = mkOption {
                    type = types.str;
                    default = defaults.backend.jdbc.password;
                    description = "The password to connect to the database.";
                  };
                };
              });
              default = defaults.backend.jdbc;
              description = "Database connection settings";
            };
            signup = mkOption {
              type = types.submodule ({
                options = {
                  mode = mkOption {
                    type = types.str;
                    default = defaults.backend.signup.mode;
                    description = ''
                      The mode defines if new users can signup or not. It can have
                      three values:

                      - open: every new user can sign up
                      - invite: new users can sign up only if they provide a correct
                        invitation key. Invitation keys can be generated by the
                        server.
                      - closed: signing up is disabled.
                    '';
                  };
                  new-invite-password = mkOption {
                    type = types.str;
                    default = defaults.backend.signup.new-invite-password;
                    description = ''
                      If mode == 'invite', a password must be provided to generate
                      invitation keys. It must not be empty.
                    '';
                  };
                  invite-time = mkOption {
                    type = types.str;
                    default = defaults.backend.signup.invite-time;
                    description = ''
                      If mode == 'invite', this is the period an invitation token is
                      considered valid.
                    '';
                  };
                };
              });
              default = defaults.backend.signup;
              description = "Registration settings";
            };
            files = mkOption {
              type = types.submodule({
                options = {
                  chunk-size = mkOption {
                    type = types.int;
                    default = defaults.backend.files.chunk-size;
                    description = ''
                      Defines the chunk size (in bytes) used to store the files.
                      This will affect the memory footprint when uploading and
                      downloading files. At most this amount is loaded into RAM for
                      down- and uploading.

                      It also defines the chunk size used for the blobs inside the
                      database.
                    '';
                  };
                  valid-mime-types = mkOption {
                    type = types.listOf types.str;
                    default = defaults.backend.files.valid-mime-types;
                    description = ''
                      The file content types that are considered valid. Docspell
                      will only pass these files to processing. The processing code
                      itself has also checks for which files are supported and which
                      not. This affects the uploading part and is a first check to
                      avoid that 'bad' files get into the system.
                    '';
                  };
                };
              });
              default = defaults.backend.files;
              description= "Settings for how files are stored.";
            };
          };
        });
        default = defaults.backend;
        description = "Configuration for the backend";
      };


    };
  };

  ## implementation
  config = mkIf config.services.docspell-restserver.enable {

    users.users."${user}" = mkIf (cfg.runAs == null) {
      name = user;
      isSystemUser = false;
      createHome = true;
      home = "/var/docspell";
      description = "Docspell user";
    };

    systemd.services.docspell-restserver =
    let
      cmd = "${pkgs.docspell.server}/bin/docspell-restserver ${configFile}";
    in
    {
      description = "Docspell Rest Server";
      after = [ "networking.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.gawk ];
      preStart = ''
      '';

      script =
        "${pkgs.su}/bin/su -s ${pkgs.bash}/bin/sh ${user} -c \"${cmd}\"";
    };
  };
}
