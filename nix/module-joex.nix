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
        default = "docspell-joex1";
        description = "The node id. Must be unique across all docspell nodes.";
      };

      base-url = mkOption {
        type = types.str;
        default = "http://localhost:7878";
        description = "The base url where attentive is deployed.";
      };

      bind = mkOption {
        type = types.submodule({
          options = {
            address = mkOption {
              type = types.str;
              default = "localhost";
              description = "The address to bind the REST server to.";
            };
            port = mkOption {
              type = types.int;
              default = 7878;
              description = "The port to bind the REST server";
            };
          };
        });
        default = {
          address = "localhost";
          port = 7878;
        };
        description = "Address and port bind the rest server.";
      };

      jdbc = mkOption {
        type = types.submodule ({
          options = {
            url = mkOption {
              type = types.str;
              default = "jdbc:h2:///tmp/docspell-demo.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE";
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
              default = "sa";
              description = "The user name to connect to the database.";
            };
            password = mkOption {
              type = types.str;
              default = "";
              description = "The password to connect to the database.";
            };
          };
        });
        default = {
          url = "jdbc:h2:///tmp/docspell-demo.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE";
          user = "sa";
          password = "";
        };
        description = "Database connection settings";
      };

      scheduler = mkOption {
        type = types.submodule({
          options = {
            pool-size = mkOption {
              type = types.int;
              default = 2;
              description = "Number of processing allowed in parallel.";
            };
            counting-scheme = mkOption {
              type = types.str;
              default = "4,1";
              description = ''
                A counting scheme determines the ratio of how high- and low-prio
                jobs are run. For example: 4,1 means run 4 high prio jobs, then
                1 low prio and then start over.
              '';
            };
            retries = mkOption {
              type = types.int;
              default = 5;
              description = ''
                How often a failed job should be retried until it enters failed
                state. If a job fails, it becomes "stuck" and will be retried
                after a delay.
              '';
            };
            retry-delay = mkOption {
              type = types.str;
              default = "1 minute";
              description = ''
                The delay until the next try is performed for a failed job. This
                delay is increased exponentially with the number of retries.
              '';
            };
            log-buffer-size = mkOption {
              type = types.int;
              default = 500;
              description = ''
                The queue size of log statements from a job.
              '';
            };
            wakeup-period = mkOption {
              type = types.str;
              default = "30 minutes";
              description = ''
                If no job is left in the queue, the scheduler will wait until a
                notify is requested (using the REST interface). To also retry
                stuck jobs, it will notify itself periodically.
              '';
            };
          };
        });
        default = {
          pool-size = 2;
          counting-scheme = "4,1";
          retries = 5;
          retry-delay = "1 minute";
          log-buffer-size = 500;
          wakeup-period = "30 minutes";
        };
        description = "Settings for the scheduler";
      };

      extraction =
        let
          gsdefaults =  {
            program = "${pkgs.ghostscript}/bin/gs";
            args = [ "-dNOPAUSE" "-dBATCH" "-dSAFER" "-sDEVICE=tiffscaled8" "-sOutputFile={{outfile}}" "{{infile}}" ];
            timeout = "5 minutes";
          };
          unpaperdefaults = {
            program = "${pkgs.unpaper}/bin/unpaper";
            args = [ "{{infile}}" "{{outfile}}" ];
            timeout = "5 minutes";
          };
          tesseractdefaults = {
            program = "${pkgs.tesseract4}/bin/tesseract";
            args = ["{{file}}" "stdout" "-l" "{{lang}}" ];
            timeout = "5 minutes";
          };
        in
        mkOption {
        type = types.submodule({
          options = {
            page-range = mkOption {
              type = types.submodule({
                options = {
                  begin = mkOption {
                    type = types.int;
                    default = 10;
                    description = "Specifies the first N pages of a file to process.";
                  };
                };
              });
              default = {
                begin = 10;
              };
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
                    default = "/tmp/docspell-extraction";
                    description = "Directory where the extraction processes can put their temp files";
                  };
                  command = mkOption {
                    type = types.submodule({
                      options = {
                        program = mkOption {
                          type = types.str;
                          default = gsdefaults.program;
                          description = "The path to the executable.";
                        };
                        args = mkOption {
                          type = types.listOf types.str;
                          default = gsdefaults.args;
                          description = "The arguments to the program";
                        };
                        timeout = mkOption {
                          type = types.str;
                          default = gsdefaults.timeout;
                          description = "The timeout when executing the command";
                        };
                      };
                    });
                    default = gsdefaults;
                    description = "The system command";
                  };
                };
              });
              default = {
                command = gsdefaults;
                working-dir = "/tmp/docspell-extraction";
              };
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
                          default = unpaperdefaults.program;
                          description = "The path to the executable.";
                        };
                        args = mkOption {
                          type = types.listOf types.str;
                          default = unpaperdefaults.args;
                          description = "The arguments to the program";
                        };
                        timeout = mkOption {
                          type = types.str;
                          default = unpaperdefaults.timeout;
                          description = "The timeout when executing the command";
                        };
                      };
                    });
                    default = unpaperdefaults;
                    description = "The system command";
                  };
                };
              });
              default = {
                command = unpaperdefaults;
              };
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
                          default = tesseractdefaults.program;
                          description = "The path to the executable.";
                        };
                        args = mkOption {
                          type = types.listOf types.str;
                          default = tesseractdefaults.args;
                          description = "The arguments to the program";
                        };
                        timeout = mkOption {
                          type = types.str;
                          default = tesseractdefaults.timeout;
                          description = "The timeout when executing the command";
                        };
                      };
                    });
                    default = tesseractdefaults;
                    description = "The system command";
                  };
                };
              });
              default = {
                command = tesseractdefaults;
              };
              description = "The tesseract command.";
            };
          };
        });
        default = {
          page-range = {
            begin = 10;
          };
          ghostscript = {
            command = gsdefaults;
            working-dir = "/tmp/docspell-extraction";
          };
        };
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
