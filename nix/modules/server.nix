{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.docspell-restserver;
  # Extract the config without the extraConfig attribute. It will be merged later
  declared_config = attrsets.filterAttrs (n: v: n != "extraConfig") cfg;
  user =
    if cfg.runAs == null
    then "docspell"
    else cfg.runAs;
  defaults = {
    app-name = "Docspell";
    app-id = "rest1";
    base-url = "http://localhost:7880";
    internal-url = "http://localhost:7880";
    max-item-page-size = 200;
    max-note-length = 180;
    show-classification-settings = true;
    bind = {
      address = "localhost";
      port = 7880;
    };
    server-options = {
      enable-http-2 = false;
      max-connections = 1024;
      response-timeout = "45s";
    };
    logging = {
      minimum-level = "Info";
      format = "Fancy";
      levels = {
        "docspell" = "Info";
        "org.flywaydb" = "Info";
        "binny" = "Info";
        "org.http4s" = "Info";
      };
    };
    integration-endpoint = {
      enabled = false;
      priority = "low";
      source-name = "integration";
      allowed-ips = {
        enabled = false;
        ips = ["127.0.0.1"];
      };
      http-basic = {
        enabled = false;
        realm = "Docspell Integration";
        user = "docspell-int";
        password = "docspell-int";
      };
      http-header = {
        enabled = false;
        header-name = "Docspell-Integration";
        header-value = "some-secret";
      };
    };
    admin-endpoint = {
      secret = "";
    };
    full-text-search = {
      enabled = false;
      backend = "solr";
      solr = {
        url = "http://localhost:8983/solr/docspell";
        commit-within = 1000;
        log-verbose = false;
        def-type = "lucene";
        q-op = "OR";
      };
      postgresql = {
        use-default-connection = false;
        jdbc = {
          url = "jdbc:postgresql://server:5432/db";
          user = "pguser";
          password = "";
        };
        pg-config = {};
        pg-query-parser = "websearch_to_tsquery";
        pg-rank-normalization = [4];
      };
    };
    auth = {
      server-secret = "hex:caffee";
      session-valid = "5 minutes";
      on-account-source-conflict = "fail";
      remember-me = {
        enabled = true;
        valid = "30 days";
      };
    };
    download-all = {
      max-files = 500;
      max-size = "1400M";
    };
    openid = {
      enabled = false;
      display = "";
      provider = {
        provider-id = null;
        client-id = null;
        client-secret = null;
        scope = "profile";
        authorize-url = null;
        token-url = null;
        logout-url = "";
        user-url = null;
        sign-key = "";
        sig-algo = "RS256";
      };
      user-key = "preferred_username";
      collective-key = "lookup:preferred_username";
    };
    backend = {
      mail-debug = false;
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
      addons = {
        enabled = false;
        allow-impure = true;
        allowed-urls = ["*"];
        denied-urls = [];
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
      package = mkPackageOption pkgs "docspell-restserver" {};
      runAs = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Specify a user for running the application. If null, a new
          user is created.
        '';
      };
      jvmArgs = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["-J-Xmx1G"];
        description = "The options passed to the executable for setting jvm arguments.";
      };
      configFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = literalExpression ''"''${config.sops.secrets.docspell_restserver_config.path}"'';
        description = ''
          Path to an existing configuration file.
          If null, a configuration file will be generated at /etc/docspell-restserver.conf
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

      internal-url = mkOption {
        type = types.str;
        default = defaults.internal-url;
        description = ''
          This url is the base url for reaching this server internally.
          While you might set `base-url` to some external address (like
          mydocs.myserver.com), the `internal-url` must be set such that
          other nodes can reach this server.
        '';
      };

      max-item-page-size = mkOption {
        type = types.int;
        default = defaults.max-item-page-size;
        description = ''
          This is a hard limit to restrict the size of a batch that is
          returned when searching for items. The user can set this limit
          within the client config, but it is restricted by the server to
          the number defined here. An admin might choose a lower number
          depending on the available resources.
        '';
      };

      max-note-length = mkOption {
        type = types.int;
        default = defaults.max-note-length;
        description = ''
          The number of characters to return for each item notes when
          searching. Item notes may be very long, when returning them with
          all the results from a search, they add quite some data to return.
          In order to keep this low, a limit can be defined here.
        '';
      };

      show-classification-settings = mkOption {
        type = types.bool;
        default = defaults.show-classification-settings;
        description = ''
          This defines whether the classification form in the collective
          settings is displayed or not. If all joex instances have document
          classification disabled, it makes sense to hide its settings from
          users.
        '';
      };

      bind = mkOption {
        type = types.submodule {
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
        };
        default = defaults.bind;
        description = "Address and port bind the rest server.";
      };

      server-options = mkOption {
        type = types.submodule {
          options = {
            enable-http-2 = mkOption {
              type = types.bool;
              default = defaults.server-options.enable-http-2;
              description = "Whether to enable http2";
            };
            max-connections = mkOption {
              type = types.int;
              default = defaults.server-options.max-connections;
              description = "Maximum number of client connections";
            };
            response-timeout = mkOption {
              type = types.str;
              default = defaults.server-options.response-timeout;
              description = "Timeout when waiting for the response.";
            };
          };
        };
        default = defaults.server-options;
        description = "Tuning the http server";
      };

      logging = mkOption {
        type = types.submodule {
          options = {
            minimum-level = mkOption {
              type = types.str;
              default = defaults.logging.minimum-level;
              description = "The minimum level for logging to control verbosity.";
            };
            format = mkOption {
              type = types.str;
              default = defaults.logging.format;
              description = "The log format. One of: Fancy, Plain, Json or Logfmt";
            };
            levels = mkOption {
              type = types.attrs;
              default = defaults.logging.levels;
              description = "Set of logger and their levels";
            };
          };
        };
        default = defaults.logging;
        description = "Settings for logging";
      };

      auth = mkOption {
        type = types.submodule {
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
            on-account-source-conflict = mkOption {
              type = types.enum ["fail" "convert"];
              default = defaults.auth.on-account-source-conflict;
              description = ''
                Accounts can be local or defined at a remote provider and
                integrated via OIDC. If the same account is defined in both
                sources, docspell by default fails if a user mixes logins (e.g.
                when registering a user locally and then logging in with the
                same user via OIDC). When set to `convert` docspell treats it as
                being the same and simply updates the account to reflect the new
                account source.
              '';
            };
            remember-me = mkOption {
              type = types.submodule {
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    default = defaults.auth.remember-me.enabled;
                    description = "Whether to enable remember me.";
                  };
                  valid = mkOption {
                    type = types.str;
                    default = defaults.auth.remember-me.valid;
                    description = "The time a remember-me token is valid.";
                  };
                };
              };
              default = defaults.auth.remember-me;
              description = "Settings for Remember-Me";
            };
          };
        };
        default = defaults.auth;
        description = "Authentication";
      };

      download-all = mkOption {
        type = types.submodule {
          options = {
            max-files = mkOption {
              type = types.int;
              default = defaults.download-all.max-files;
              description = "How many files to allow in a zip.";
            };
            max-size = mkOption {
              type = types.str;
              default = defaults.download-all.max-size;
              description = "The maximum (uncompressed) size of the zip file contents.";
            };
          };
        };
        default = defaults.download-all;
        description = "";
      };

      openid = mkOption {
        type = types.listOf (types.submodule {
          options = {
            enabled = mkOption {
              type = types.bool;
              default = defaults.openid.enabled;
              description = "Whether to use these settings.";
            };
            display = mkOption {
              type = types.str;
              default = defaults.openid.display;
              example = "via Keycloak";
              description = "The name for the button on the login page.";
            };
            user-key = mkOption {
              type = types.str;
              default = defaults.openid.user-key;
              description = "The key to retrieve the username";
            };
            collective-key = mkOption {
              type = types.str;
              default = defaults.openid.collective-key;
              description = "How to retrieve the collective name.";
            };
            provider = mkOption {
              type = types.submodule {
                options = {
                  provider-id = mkOption {
                    type = types.str;
                    default = defaults.openid.provider.provider-id;
                    example = "keycloak";
                    description = "The id of the provider, used in the URL and to distinguish other providers.";
                  };
                  client-id = mkOption {
                    type = types.str;
                    default = defaults.openid.provider.client-id;
                    description = "The client-id as registered at the OP.";
                  };
                  client-secret = mkOption {
                    type = types.str;
                    default = defaults.openid.provider.client-secret;
                    description = "The client-secret as registered at the OP.";
                  };
                  scope = mkOption {
                    type = types.str;
                    default = defaults.openid.provider.scope;
                    description = "A scope to define what data to return from OP";
                  };
                  authorize-url = mkOption {
                    type = types.str;
                    default = defaults.openid.provider.authorize-url;
                    description = "The URL used to authenticate the user";
                  };
                  token-url = mkOption {
                    type = types.str;
                    default = defaults.openid.provider.token-url;
                    description = "The URL used to retrieve the token.";
                  };
                  logout-url = mkOption {
                    type = types.str;
                    default = defaults.openid.provider.logout-url;
                    description = "The URL used for user's logout.";
                  };
                  user-url = mkOption {
                    type = types.nullOr types.str;
                    default = defaults.openid.provider.user-url;
                    description = "The URL to the user-info endpoint.";
                  };
                  sign-key = mkOption {
                    type = types.str;
                    default = defaults.openid.provider.sign-key;
                    description = "The key for verifying the jwt signature.";
                  };
                  sig-algo = mkOption {
                    type = types.str;
                    default = defaults.openid.provider.sig-algo;
                    description = "The expected algorithm used to sign the token.";
                  };
                };
              };
              default = defaults.openid.provider;
              description = "The config for an OpenID Connect provider.";
            };
          };
        });
        default = [];
        description = "A list of OIDC provider configurations.";
      };

      integration-endpoint = mkOption {
        type = types.submodule {
          options = {
            enabled = mkOption {
              type = types.bool;
              default = defaults.integration-endpoint.enabled;
              description = "Whether the endpoint is globally enabled or disabled.";
            };
            priority = mkOption {
              type = types.str;
              default = defaults.integration-endpoint.priority;
              description = "The priority to use when submitting files through this endpoint.";
            };
            source-name = mkOption {
              type = types.str;
              default = defaults.integration-endpoint.source-name;
              description = ''
                The name used for the item "source" property when uploaded through this endpoint.
              '';
            };
            allowed-ips = mkOption {
              type = types.submodule {
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    default = defaults.integration-endpoint.allowed-ips.enabled;
                    description = "Enable/Disable this protection";
                  };
                  ips = mkOption {
                    type = types.listOf types.str;
                    default = defaults.integration-endpoint.allowed-ips.ips;
                    description = "The ips/ip patterns to allow";
                  };
                };
              };
              default = defaults.integration-endpoint.allowed-ips;
              description = ''
                IPv4 addresses to allow access. An empty list, if enabled,
                prohibits all requests. IP addresses may be specified as simple
                globs: a part marked as `*' matches any octet, like in
                `192.168.*.*`. The `127.0.0.1' (the default) matches the
                loopback address.
              '';
            };
            http-basic = mkOption {
              type = types.submodule {
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    default = defaults.integration-endpoint.http-basic.enabled;
                    description = "Enable/Disable this protection";
                  };
                  realm = mkOption {
                    type = types.str;
                    default = defaults.integration-endpoint.http-basic.realm;
                    description = "The realm name to provide to the client.";
                  };
                  user = mkOption {
                    type = types.str;
                    default = defaults.integration-endpoint.http-basic.user;
                    description = "The user name to check.";
                  };
                  password = mkOption {
                    type = types.str;
                    default = defaults.integration-endpoint.http-basic.password;
                    description = "The password to check.";
                  };
                };
              };
              default = defaults.integration-endpoint.http-basic;
              description = ''
                Requests are expected to use http basic auth when uploading files.
              '';
            };
            http-header = mkOption {
              type = types.submodule {
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    default = defaults.integration-endpoint.http-header.enabled;
                    description = "Enable/Disable this protection";
                  };
                  header-name = mkOption {
                    type = types.str;
                    default = defaults.integration-endpoint.http-header.header-name;
                    description = "The header to extract from the request.";
                  };
                  header-value = mkOption {
                    type = types.str;
                    default = defaults.integration-endpoint.http-basic.header-value;
                    description = "The value of the header to check.";
                  };
                };
              };
              default = defaults.integration-endpoint.http-header;
              description = ''
                Requests are expected to supply some specific header when
                uploading files.
              '';
            };
          };
        };
        default = defaults.integration-endpoint;
        description = ''
          This endpoint allows to upload files to any collective. The
          intention is that local software integrates with docspell more
          easily. Therefore the endpoint is not protected by the usual
          means.

          For security reasons, this endpoint is disabled by default. If
          enabled, you can choose from some ways to protect it. It may be a
          good idea to further protect this endpoint using a firewall, such
          that outside traffic is not routed.

          NOTE: If all protection methods are disabled, the endpoint is not
          protected at all!
        '';
      };

      admin-endpoint = mkOption {
        type = types.submodule {
          options = {
            secret = mkOption {
              type = types.str;
              default = defaults.admin-endpoint.secret;
              description = "The secret used to call admin endpoints.";
            };
          };
        };
        default = defaults.admin-endpoint;
        description = "An endpoint for administration tasks.";
      };

      full-text-search = mkOption {
        type = types.submodule {
          options = {
            enabled = mkOption {
              type = types.bool;
              default = defaults.full-text-search.enabled;
              description = ''
                The full-text search feature can be disabled. It requires an
                additional index server which needs additional memory and disk
                space. It can be enabled later any time.
              '';
            };
            backend = mkOption {
              type = types.str;
              default = defaults.full-text-search.backend;
              description = "The backend to use, either solr or postgresql";
            };
            solr = mkOption {
              type = types.submodule {
                options = {
                  url = mkOption {
                    type = types.str;
                    default = defaults.full-text-search.solr.url;
                    description = "The URL to solr";
                  };
                  commit-within = mkOption {
                    type = types.int;
                    default = defaults.full-text-search.solr.commit-within;
                    description = "Used to tell solr when to commit the data";
                  };
                  log-verbose = mkOption {
                    type = types.bool;
                    default = defaults.full-text-search.solr.log-verbose;
                    description = "If true, logs request and response bodies";
                  };
                  def-type = mkOption {
                    type = types.str;
                    default = defaults.full-text-search.solr.def-type;
                    description = ''
                      The defType parameter to lucene that defines the parser to
                      use. You might want to try "edismax" or look here:
                      https://solr.apache.org/guide/8_4/query-syntax-and-parsing.html#query-syntax-and-parsing
                    '';
                  };
                  q-op = mkOption {
                    type = types.str;
                    default = defaults.full-text-search.solr.q-op;
                    description = "The default combiner for tokens. One of {AND, OR}.";
                  };
                };
              };
              default = defaults.full-text-search.solr;
              description = "Configuration for the SOLR backend.";
            };

            postgresql = mkOption {
              type = types.submodule {
                options = {
                  use-default-connection = mkOption {
                    type = types.bool;
                    default = defaults.full-text-search.postgresql.use-default-connection;
                    description = "Whether to use the primary db connection.";
                  };
                  jdbc = mkOption {
                    type = types.submodule {
                      options = {
                        url = mkOption {
                          type = types.str;
                          default = defaults.jdbc.url;
                          description = ''
                            The URL to the database.
                          '';
                        };
                        user = mkOption {
                          type = types.str;
                          default = defaults.jdbc.user;
                          description = "The user name to connect to the database.";
                        };
                        password = mkOption {
                          type = types.str;
                          default = defaults.jdbc.password;
                          description = "The password to connect to the database.";
                        };
                      };
                    };
                    default = defaults.full-text-search.postgresql.jdbc;
                    description = "Database connection settings";
                  };
                  pg-config = mkOption {
                    type = types.attrs;
                    default = defaults.full-text-search.postgresql.pg-config;
                    description = "";
                  };
                  pg-query-parser = mkOption {
                    type = types.str;
                    default = defaults.full-text-search.postgresql.pg-query-parser;
                    description = "";
                  };
                  pg-rank-normalization = mkOption {
                    type = types.listOf types.int;
                    default = defaults.full-text-search.postgresql.pg-rank-normalization;
                    description = "";
                  };
                };
              };
              default = defaults.full-text-search.postgresql;
              description = "PostgreSQL for fulltext search";
            };
          };
        };
        default = defaults.full-text-search;
        description = "Configuration for full-text search.";
      };

      backend = mkOption {
        type = types.submodule {
          options = {
            mail-debug = mkOption {
              type = types.bool;
              default = defaults.backend.mail-debug;
              description = ''
                Enable or disable debugging for e-mail related functionality. This
                applies to both sending and receiving mails. For security reasons
                logging is not very extensive on authentication failures. Setting
                this to true, results in a lot of data printed to stdout.
              '';
            };
            jdbc = mkOption {
              type = types.submodule {
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
              };
              default = defaults.backend.jdbc;
              description = "Database connection settings";
            };
            signup = mkOption {
              type = types.submodule {
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
              };
              default = defaults.backend.signup;
              description = "Registration settings";
            };
            files = mkOption {
              type = types.submodule {
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
              };
              default = defaults.backend.files;
              description = "Settings for how files are stored.";
            };
            addons = mkOption {
              type = types.submodule {
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    default = defaults.backend.addons.enabled;
                    description = "Enable this feature";
                  };
                  allow-impure = mkOption {
                    type = types.bool;
                    default = defaults.backend.addons.allow-impure;
                    description = "Allow impure addons";
                  };
                  allowed-urls = mkOption {
                    type = types.listOf types.str;
                    default = defaults.backend.addons.allowed-urls;
                    description = "Url patterns of addons to be allowed";
                  };
                  denied-urls = mkOption {
                    type = types.listOf types.str;
                    default = defaults.backend.addons.denied-urls;
                    description = "Url patterns to deny to install";
                  };
                };
              };
              default = defaults.backend.addons;
              description = "Addon config";
            };
          };
        };
        default = defaults.backend;
        description = "Configuration for the backend";
      };
      extraConfig = mkOption {
        type = types.attrs;
        description = "Extra configuration for docspell server. Overwrites values in case of a conflict.";
        default = {};
        example = ''
          {
            files = {
              default-store = "minio";
              stores = {
                minio = {
                  enabled = true;
                };
              };
            };
          }
        '';
      };
    };
  };

  ## implementation
  config = mkIf config.services.docspell-restserver.enable {
    users.users."${user}" = mkIf (cfg.runAs == null) {
      name = user;
      isSystemUser = true;
      createHome = true;
      home = "/var/docspell";
      description = "Docspell user";
      group = user;
    };
    users.groups."${user}" = mkIf (cfg.runAs == null) {};

    environment.etc."docspell-restserver.conf" = mkIf (cfg.configFile == null) {
      text = ''
        {"docspell": {"server":
          ${builtins.toJSON (lib.recursiveUpdate declared_config cfg.extraConfig)}
        }}
      '';
      user = user;
      group = user;
      mode = "0400";
    };

    systemd.services.docspell-restserver = let
      args = builtins.concatStringsSep " " cfg.jvmArgs;
      configFile = if cfg.configFile == null
        then "/etc/docspell-restserver.conf"
        else "${cfg.configFile}";
      cmd = "${lib.getExe' cfg.package "docspell-restserver"} ${args} -- ${configFile}";
    in {
      description = "Docspell Rest Server";
      after = ["networking.target"];
      wantedBy = ["multi-user.target"];
      path = [pkgs.gawk];
      preStart = ''
      '';

      script = "${pkgs.su}/bin/su -s ${pkgs.bash}/bin/sh ${user} -c \"${cmd}\"";
    };
  };
}
