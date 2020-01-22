{config, lib, pkgs, ...}:

with lib;
let
  cfg = config.services.docspell-joex;
  user = if cfg.runAs == null then "docspell" else cfg.runAs;
  configFile = pkgs.writeText "docspell-joex.conf" ''
  {"docspell": { "joex":
       ${builtins.toJSON cfg}
  }}
  '';
  defaults = {
    app-id = "joex1";
    base-url = "http://localhost:7878";
    bind = {
      address = "localhost";
      port = 7878;
    };
    jdbc = {
      url = "jdbc:h2:///tmp/docspell-demo.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE";
      user = "sa";
      password = "";
    };
    scheduler = {
      pool-size = 2;
      counting-scheme = "4,1";
      retries = 5;
      retry-delay = "1 minute";
      log-buffer-size = 500;
      wakeup-period = "30 minutes";
    };
    extraction = {
      page-range = {
        begin = 10;
      };
      ghostscript =  {
        working-dir = "/tmp/docspell-extraction";
        command = {
          program = "${pkgs.ghostscript}/bin/gs";
          args = [ "-dNOPAUSE" "-dBATCH" "-dSAFER" "-sDEVICE=tiffscaled8" "-sOutputFile={{outfile}}" "{{infile}}" ];
          timeout = "5 minutes";
        };
      };
      unpaper = {
        command = {
          program = "${pkgs.unpaper}/bin/unpaper";
          args = [ "{{infile}}" "{{outfile}}" ];
          timeout = "5 minutes";
        };
      };
      tesseract = {
        command= {
          program = "${pkgs.tesseract4}/bin/tesseract";
          args = ["{{file}}" "stdout" "-l" "{{lang}}" ];
          timeout = "5 minutes";
        };
      };
    };
  };
in {

  ## interface
  options = {
    services.docspell-joex = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable docspell docspell job executor.";
      };
      runAs = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Specify a user for running the application. If null, a new
          user is created.
        '';
      };

      app-id = mkOption {
        type = types.str;
        default = defaults.app-id;
        description = "The node id. Must be unique across all docspell nodes.";
      };

      base-url = mkOption {
        type = types.str;
        default = defaults.base-url;
        description = "The base url where attentive is deployed.";
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

      jdbc = mkOption {
        type = types.submodule ({
          options = {
            url = mkOption {
              type = types.str;
              default = defaults.jdbc.url;
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
              default = defaults.jdbc.user;
              description = "The user name to connect to the database.";
            };
            password = mkOption {
              type = types.str;
              default = defaults.jdbc.password;
              description = "The password to connect to the database.";
            };
          };
        });
        default = defaults.jdbc;
        description = "Database connection settings";
      };

      scheduler = mkOption {
        type = types.submodule({
          options = {
            pool-size = mkOption {
              type = types.int;
              default = defaults.scheduler.pool-size;
              description = "Number of processing allowed in parallel.";
            };
            counting-scheme = mkOption {
              type = types.str;
              default = defaults.scheduler.counting-scheme;
              description = ''
                A counting scheme determines the ratio of how high- and low-prio
                jobs are run. For example: 4,1 means run 4 high prio jobs, then
                1 low prio and then start over.
              '';
            };
            retries = mkOption {
              type = types.int;
              default = defaults.scheduler.retries;
              description = ''
                How often a failed job should be retried until it enters failed
                state. If a job fails, it becomes "stuck" and will be retried
                after a delay.
              '';
            };
            retry-delay = mkOption {
              type = types.str;
              default = defaults.scheduler.retry-delay;
              description = ''
                The delay until the next try is performed for a failed job. This
                delay is increased exponentially with the number of retries.
              '';
            };
            log-buffer-size = mkOption {
              type = types.int;
              default = defaults.scheduler.log-buffer-size;
              description = ''
                The queue size of log statements from a job.
              '';
            };
            wakeup-period = mkOption {
              type = types.str;
              default = defaults.scheduler.wakeup-period;
              description = ''
                If no job is left in the queue, the scheduler will wait until a
                notify is requested (using the REST interface). To also retry
                stuck jobs, it will notify itself periodically.
              '';
            };
          };
        });
        default = defaults.scheduler;
        description = "Settings for the scheduler";
      };

      extraction = mkOption {
        type = types.submodule({
          options = {
            page-range = mkOption {
              type = types.submodule({
                options = {
                  begin = mkOption {
                    type = types.int;
                    default = defaults.extraction.page-range.begin;
                    description = "Specifies the first N pages of a file to process.";
                  };
                };
              });
              default = defaults.extraction.page-range;
              description = ''
                Defines what pages to process. If a PDF with 600 pages is
                submitted, it is probably not necessary to scan through all of
                them. This would take a long time and occupy resources for no
                value. The first few pages should suffice. The default is first
                10 pages.

                If you want all pages being processed, set this number to -1.

                Note: if you change the ghostscript command below, be aware that
                this setting (if not -1) will add another parameter to the
                beginning of the command.
              '';
            };
            ghostscript = mkOption {
              type = types.submodule({
                options = {
                  working-dir = mkOption {
                    type = types.str;
                    default = defaults.extraction.ghostscript.working-dir;
                    description = "Directory where the extraction processes can put their temp files";
                  };
                  command = mkOption {
                    type = types.submodule({
                      options = {
                        program = mkOption {
                          type = types.str;
                          default = defaults.extraction.ghostscript.command.program;
                          description = "The path to the executable.";
                        };
                        args = mkOption {
                          type = types.listOf types.str;
                          default = defaults.extraction.ghostscript.command.args;
                          description = "The arguments to the program";
                        };
                        timeout = mkOption {
                          type = types.str;
                          default = defaults.extraction.ghostscript.command.timeout;
                          description = "The timeout when executing the command";
                        };
                      };
                    });
                    default = defaults.extraction.ghostscript.command;
                    description = "The system command";
                  };
                };
              });
              default = defaults.extraction.ghostscript;
              description = "The ghostscript command.";
            };
            unpaper = mkOption {
              type = types.submodule({
                options = {
                  command = mkOption {
                    type = types.submodule({
                      options = {
                        program = mkOption {
                          type = types.str;
                          default = defaults.extraction.unpaper.command.program;
                          description = "The path to the executable.";
                        };
                        args = mkOption {
                          type = types.listOf types.str;
                          default = defaults.extraction.unpaper.command.args;
                          description = "The arguments to the program";
                        };
                        timeout = mkOption {
                          type = types.str;
                          default = defaults.extraction.unpaper.command.timeout;
                          description = "The timeout when executing the command";
                        };
                      };
                    });
                    default = defaults.extraction.unpaper.command;
                    description = "The system command";
                  };
                };
              });
              default = defaults.extraction.unpaper;
              description = "The unpaper command.";
            };
            tesseract = mkOption {
              type = types.submodule({
                options = {
                  command = mkOption {
                    type = types.submodule({
                      options = {
                        program = mkOption {
                          type = types.str;
                          default = defaults.extraction.tesseract.command.program;
                          description = "The path to the executable.";
                        };
                        args = mkOption {
                          type = types.listOf types.str;
                          default = defaults.extraction.tesseract.command.args;
                          description = "The arguments to the program";
                        };
                        timeout = mkOption {
                          type = types.str;
                          default = defaults.extraction.tesseract.command.timeout;
                          description = "The timeout when executing the command";
                        };
                      };
                    });
                    default = defaults.extraction.tesseract.command;
                    description = "The system command";
                  };
                };
              });
              default = defaults.extraction.tesseract;
              description = "The tesseract command.";
            };
          };
        });
        default = defaults.extraction;
        description = ''
          Configuration of text extraction

          Extracting text currently only work for image and pdf files. It
          will first runs ghostscript to create a gray image from a
          pdf. Then unpaper is run to optimize the image for the upcoming
          ocr, which will be done by tesseract. All these programs must be
          available in your PATH or the absolute path can be specified
          below.
        '';
      };
    };
  };

  ## implementation
  config = mkIf config.services.docspell-joex.enable {

    users.users."${user}" = mkIf (cfg.runAs == null) {
      name = user;
      isSystemUser = true;
      description = "Docspell user";
    };

    systemd.services.docspell-joex =
    let
      cmd = "${pkgs.docspell.joex}/bin/docspell-joex ${configFile}";
    in
    {
      description = "Docspell Joex";
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
