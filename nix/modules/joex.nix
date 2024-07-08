{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.docspell-joex;
  # Extract the config without the extraConfig attribute. It will be merged later
  declared_config = attrsets.filterAttrs (n: v: n != "extraConfig") cfg;
  user =
    if cfg.runAs == null
    then "docspell"
    else cfg.runAs;
  defaults = {
    app-id = "joex1";
    base-url = "http://localhost:7878";
    bind = {
      address = "localhost";
      port = 7878;
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
    mail-debug = false;
    jdbc = {
      url = "jdbc:h2:///tmp/docspell-demo.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE";
      user = "sa";
      password = "";
    };
    send-mail = {
      list-id = "";
    };
    user-tasks = {
      scan-mailbox = {
        max-folders = 50;
        mail-chunk-size = 50;
        max-mails = 500;
      };
    };
    scheduler = {
      pool-size = 2;
      counting-scheme = "4,1";
      retries = 2;
      retry-delay = "1 minute";
      log-buffer-size = 500;
      wakeup-period = "30 minutes";
    };
    periodic-scheduler = {
      wakeup-period = "10 minutes";
    };
    house-keeping = {
      schedule = "Sun *-*-* 00:00:00 UTC";
      cleanup-invites = {
        enabled = true;
        older-than = "30 days";
      };
      cleanup-jobs = {
        enabled = true;
        older-than = "30 days";
        delete-batch = 100;
      };
      cleanup-remember-me = {
        enabled = true;
        older-than = "30 days";
      };
      cleanup-downloads = {
        enabled = true;
        older-than = "14 days";
      };
      check-nodes = {
        enabled = true;
        min-not-found = 2;
      };
    };
    update-check = {
      enabled = false;
      test-run = false;
      schedule = "Sun *-*-* 00:00:00 UTC";
      sender-account = "";
      smtp-id = "";
      recipients = [];
      subject = "Docspell {{ latestVersion }} is available";
      body = ''
        Hello,

        You are currently running Docspell {{ currentVersion }}. Version *{{ latestVersion }}*
        is now available, which was released on {{ releasedAt }}. Check the release page at:

        <https://github.com/eikek/docspell/releases/latest>

        Have a nice day!

        Docpell Update Check
      '';
    };
    extraction = {
      pdf = {
        min-text-len = 500;
      };
      preview = {
        dpi = 32;
      };
      ocr = {
        max-image-size = 14000000;
        page-range = {
          begin = 10;
        };
        ghostscript = {
          working-dir = "/tmp/docspell-extraction";
          command = {
            program = "${pkgs.ghostscript}/bin/gs";
            args = ["-dNOPAUSE" "-dBATCH" "-dSAFER" "-sDEVICE=tiffscaled8" "-sOutputFile={{outfile}}" "{{infile}}"];
            timeout = "5 minutes";
          };
        };
        unpaper = {
          command = {
            program = "${pkgs.unpaper}/bin/unpaper";
            args = ["{{infile}}" "{{outfile}}"];
            timeout = "5 minutes";
          };
        };
        tesseract = {
          command = {
            program = "${pkgs.tesseract4}/bin/tesseract";
            args = ["{{file}}" "stdout" "-l" "{{lang}}"];
            timeout = "5 minutes";
          };
        };
      };
    };
    text-analysis = {
      max-length = 5000;
      nlp = {
        mode = "full";
        clear-interval = "15 minutes";
        max-due-date-years = 10;
        regex-ner = {
          max-entries = 1000;
          file-cache-time = "1 minute";
        };
      };
      classification = {
        enabled = true;
        item-count = 600;
        classifiers = [
          {
            "useSplitWords" = "true";
            "splitWordsTokenizerRegexp" = ''[\p{L}][\p{L}0-9]*|(?:\$ ?)?[0-9]+(?:\.[0-9]{2})?%?|\s+|.'';
            "splitWordsIgnoreRegexp" = ''\s+'';
            "useSplitPrefixSuffixNGrams" = "true";
            "maxNGramLeng" = "4";
            "minNGramLeng" = "1";
            "splitWordShape" = "chris4";
            "intern" = "true";
          }
        ];
      };
      working-dir = "/tmp/docspell-analysis";
    };
    convert = {
      chunk-size = 524288;
      converted-filename-part = "converted";
      max-image-size = 14000000;

      markdown = {
        internal-css = ''
          body { padding: 2em 5em; }
        '';
      };

      wkhtmlpdf = {
        command = {
          program = "";
          args = ["--encoding" "UTF-8" "-" "{{outfile}}"];
          timeout = "2 minutes";
        };
        working-dir = "/tmp/docspell-convert";
      };

      weasyprint = {
        command = {
          program = "${pkgs.python310Packages.weasyprint}/bin/weasyprint";
          args = [
            "--optimize-size"
            "all"
            "--encoding"
            "{{encoding}}"
            "-"
            "{{outfile}}"
          ];
          timeout = "2 minutes";
        };
        working-dir = "/tmp/docspell-convert";
      };

      tesseract = {
        command = {
          program = "${pkgs.tesseract4}/bin/tesseract";
          args = ["{{infile}}" "out" "-l" "{{lang}}" "pdf" "txt"];
          timeout = "5 minutes";
        };
        working-dir = "/tmp/docspell-convert";
      };

      unoconv = {
        command = {
          program = "${pkgs.unoconv}/bin/unoconv";
          args = ["-f" "pdf" "-o" "{{outfile}}" "{{infile}}"];
          timeout = "2 minutes";
        };
        working-dir = "/tmp/docspell-convert";
      };

      ocrmypdf = {
        enabled = true;
        command = {
          program = "${pkgs.ocrmypdf}/bin/ocrmypdf";
          args = [
            "-l"
            "{{lang}}"
            "--skip-text"
            "--deskew"
            "-j"
            "1"
            "{{infile}}"
            "{{outfile}}"
          ];
          timeout = "5 minutes";
        };
        working-dir = "/tmp/docspell-convert";
      };
    };
    files = {
      chunk-size = 524288;
      valid-mime-types = [];
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
      migration = {
        index-all-chunk = 10;
      };
    };
    addons = {
      working-dir = "/tmp/docspell-addons-work";
      cache-dir = "/tmp/docspell-addons-cache";
      executor-config = {
        runner = "nix-flake,docker,trivial";
        nspawn = {
          enabled = false;
          sudo-binary = "sudo";
          nspawn-binary = "systemd-nspawn";
          container-wait = "100 millis";
        };
        fail-fast = true;
        run-timeout = "15 minutes";
        nix-runner = {
          nix-binary = "${pkgs.nix}/bin/nix";
          build-timeout = "15 minutes";
        };
        docker-runner = {
          docker-binary = "${pkgs.docker}/bin/docker";
          build-timeout = "15 minutes";
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
      package = mkPackageOption pkgs "docspell-joex" {};
      runAs = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Specify a user for running the application. If null, a new
          user is created.
        '';
      };
      waitForTarget = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          If not null, joex depends on this systemd target. This is
          useful if full-text-search is enabled and the solr instance
          is running on the same machine.
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
        example = literalExpression ''"''${config.sops.secrets.docspell_joex_config.path}"'';
        description = ''
          Path to an existing configuration file.
          If null, a configuration file will be generated at /etc/docspell-joex.conf
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

      mail-debug = mkOption {
        type = types.bool;
        default = defaults.mail-debug;
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
        };
        default = defaults.jdbc;
        description = "Database connection settings";
      };

      send-mail = mkOption {
        type = types.submodule {
          options = {
            list-id = mkOption {
              type = types.str;
              default = defaults.send-mail.list-id;
              description = ''
                This is used as the List-Id e-mail header when mails are sent
                from docspell to its users (example: for notification mails). It
                is not used when sending to external recipients. If it is empty,
                no such header is added. Using this header is often useful when
                filtering mails.

                It should be a string in angle brackets. See
                https://tools.ietf.org/html/rfc2919 for a formal specification
              '';
            };
          };
        };
        default = defaults.send-mail;
        description = "Settings for sending mails.";
      };

      scheduler = mkOption {
        type = types.submodule {
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
        };
        default = defaults.scheduler;
        description = "Settings for the scheduler";
      };

      periodic-scheduler = mkOption {
        type = types.submodule {
          options = {
            wakeup-period = mkOption {
              type = types.str;
              default = defaults.periodic-scheduler.wakeup-period;
              description = ''
                A fallback to start looking for due periodic tasks regularily.
                Usually joex instances should be notified via REST calls if
                external processes change tasks. But these requests may get
                lost.
              '';
            };
          };
        };
        default = defaults.periodic-scheduler;
        description = ''
          Settings for the periodic scheduler.
        '';
      };

      user-tasks = mkOption {
        type = types.submodule {
          options = {
            scan-mailbox = mkOption {
              type = types.submodule {
                options = {
                  max-folders = mkOption {
                    type = types.int;
                    default = defaults.user-tasks.scan-mailbox.max-folders;
                    description = ''
                      A limit of how many folders to scan through. If a user
                      configures more than this, only upto this limit folders are
                      scanned and a warning is logged.
                    '';
                  };
                  mail-chunk-size = mkOption {
                    type = types.int;
                    default = defaults.user-tasks.scan-mailbox.mail-chunk-size;
                    description = ''
                      How many mails (headers only) to retrieve in one chunk.

                      If this is greater than `max-mails' it is set automatically to
                      the value of `max-mails'.
                    '';
                  };
                  max-mails = mkOption {
                    type = types.int;
                    default = defaults.user-tasks.scan-mailbox.max-mails;
                    description = ''
                      A limit on how many mails to process in one job run. This is
                      meant to avoid too heavy resource allocation to one
                      user/collective.

                      If more than this number of mails is encountered, a warning is
                      logged.
                    '';
                  };
                };
              };
              default = defaults.user-tasks.scan-mailbox;
              description = "Allows to import e-mails by scanning a mailbox.";
            };
          };
        };
        default = defaults.user-tasks;
        description = "Configuration for the user tasks.";
      };

      house-keeping = mkOption {
        type = types.submodule {
          options = {
            schedule = mkOption {
              type = types.str;
              default = defaults.house-keeping.schedule;
              description = ''
                When the house keeping tasks execute. Default is to run every
                week.
              '';
            };
            cleanup-invites = mkOption {
              type = types.submodule {
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    default = defaults.house-keeping.cleanup-invites.enabled;
                    description = "Whether this task is enabled.";
                  };
                  older-than = mkOption {
                    type = types.str;
                    default = defaults.house-keeping.cleanup-invites.older-than;
                    description = "The minimum age of invites to be deleted.";
                  };
                };
              };
              default = defaults.house-keeping.cleanup-invites;
              description = ''
                This task removes invitation keys that have been created but not
                used. The timespan here must be greater than the `invite-time'
                setting in the rest server config file.
              '';
            };
            cleanup-jobs = mkOption {
              type = types.submodule {
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    default = defaults.house-keeping.cleanup-jobs.enabled;
                    description = "Whether this task is enabled.";
                  };
                  older-than = mkOption {
                    type = types.str;
                    default = defaults.house-keeping.cleanup-jobs.older-than;
                    description = ''
                      The minimum age of jobs to delete. It is matched against the
                      `finished' timestamp.
                    '';
                  };
                  delete-batch = mkOption {
                    type = types.int;
                    default = defauts.house-keeping.cleanup-jobs.delete-batch;
                    description = ''
                      This defines how many jobs are deleted in one transaction.
                      Since the data to delete may get large, it can be configured
                      whether more or less memory should be used.
                    '';
                  };
                };
              };
              default = defaults.house-keeping.cleanup-jobs;
              description = ''
                Jobs store their log output in the database. Normally this data
                is only interesting for some period of time. The processing logs
                of old files can be removed eventually.
              '';
            };
            cleanup-remember-me = mkOption {
              type = types.submodule {
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    default = defaults.house-keeping.cleanup-remember-me.enabled;
                    description = "Whether this task is enabled.";
                  };
                  older-than = mkOption {
                    type = types.str;
                    default = defaults.house-keeping.cleanup-remember-me.older-than;
                    description = "The miminum age of remember me tokens to delete.";
                  };
                };
              };
              default = defaults.house-keeping.cleanup-remember-me;
              description = "Settings for cleaning up remember me tokens.";
            };

            cleanup-downloads = mkOption {
              type = types.submodule {
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    default = defaults.house-keeping.cleanup-downloads.enabled;
                    description = "Whether this task is enabled.";
                  };
                  older-than = mkOption {
                    type = types.str;
                    default = defaults.house-keeping.cleanup-downloads.older-than;
                    description = "The miminum age of a download file to delete.";
                  };
                };
              };
              default = defaults.house-keeping.cleanup-downloads;
              description = "";
            };

            check-nodes = mkOption {
              type = types.submodule {
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    default = defaults.house-keeping.check-nodes.enabled;
                    description = "Whether this task is enabled.";
                  };
                  min-not-found = mkOption {
                    type = types.int;
                    default = defaults.house-keeping.check-nodes.min-not-found;
                    description = "How often the node must be unreachable, before it is removed.";
                  };
                };
              };
              default = defaults.house-keeping.cleanup-nodes;
              description = "Removes node entries that are not reachable anymore.";
            };
          };
        };
        default = defaults.house-keeping;
        description = ''
          Docspell uses periodic house keeping tasks, like cleaning expired
          invites, that can be configured here.
        '';
      };

      update-check = mkOption {
        type = types.submodule {
          options = {
            enabled = mkOption {
              type = types.bool;
              default = defaults.update-check.enabled;
              description = "Whether this task is enabled.";
            };
            test-run = mkOption {
              type = types.bool;
              default = defaults.update-check.test-run;
              description = ''
                Sends the mail without checking the latest release. Can be used
                if you want to see if mail sending works, but don't want to wait
                until a new release is published.
              '';
            };
            schedule = mkOption {
              type = types.str;
              default = defaults.update-check.schedule;
              description = ''
                When the check-update task should execute. Default is to run every
                week.
              '';
            };
            sender-account = mkOption {
              type = types.str;
              default = defaults.update-check.sender-account;
              description = ''
                An account id in form of `collective/user` (or just `user` if
                collective and user name are the same). This user account must
                have at least one valid SMTP settings which are used to send the
                mail.
              '';
            };
            smtp-id = mkOption {
              type = types.str;
              default = defaults.update-check.smtp-id;
              description = ''
                The SMTP connection id that should be used for sending the mail.
              '';
            };
            recipients = mkOption {
              type = types.listOf types.str;
              default = defaults.update-check.recipients;
              example = ["josh.doe@gmail.com"];
              description = ''
                A list of recipient e-mail addresses.
              '';
            };
            subject = mkOption {
              type = types.str;
              default = defaults.update-check.subject;
              description = ''
                The subject of the mail. It supports the same variables as the body.
              '';
            };
            body = mkOption {
              type = types.str;
              default = defaults.update-check.body;
              description = ''
                The body of the mail. Subject and body can contain these
                variables which are replaced:

                - `latestVersion` the latest available version of Docspell
                - `currentVersion` the currently running (old) version of Docspell
                - `releasedAt` a date when the release was published

                The body is processed as markdown after the variables have been
                replaced.
              '';
            };
          };
        };
        default = defaults.update-check;
        description = ''
          A periodic task to check for new releases of docspell. It can
          inform about a new release via e-mail. You need to specify an
          account that has SMTP settings to use for sending.
        '';
      };

      extraction = mkOption {
        type = types.submodule {
          options = {
            pdf = mkOption {
              type = types.submodule {
                options = {
                  min-text-len = mkOption {
                    type = types.int;
                    default = defaults.extraction.pdf.min-text-len;
                    description = ''
                      For PDF files it is first tried to read the text parts of the
                      PDF. But PDFs can be complex documents and they may contain text
                      and images. If the returned text is shorter than the value
                      below, OCR is run afterwards. Then both extracted texts are
                      compared and the longer will be used.
                    '';
                  };
                };
              };
              default = defaults.extraction.pdf;
              description = "Settings for PDF extraction";
            };
            preview = mkOption {
              type = types.submodule {
                options = {
                  dpi = mkOption {
                    type = types.int;
                    default = defaults.extraction.preview.dpi;
                    description = ''
                      When rendering a pdf page, use this dpi. This results in
                      scaling the image. A standard A4 page rendered at 96dpi
                      results in roughly 790x1100px image. Using 32 results in
                      roughly 200x300px image.

                      Note, when this is changed, you might want to re-generate
                      preview images. Check the api for this, there is an endpoint
                      to regenerate all for a collective.
                    '';
                  };
                };
              };
              default = defaults.extraction.preview;
              description = "";
            };
            ocr = mkOption {
              type = types.submodule {
                options = {
                  max-image-size = mkOption {
                    type = types.int;
                    default = defaults.extraction.ocr.max-image-size;
                    description = ''
                      Images greater than this size are skipped. Note that every
                      image is loaded completely into memory for doing OCR.
                    '';
                  };
                  page-range = mkOption {
                    type = types.submodule {
                      options = {
                        begin = mkOption {
                          type = types.int;
                          default = defaults.extraction.page-range.begin;
                          description = "Specifies the first N pages of a file to process.";
                        };
                      };
                    };
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
                    type = types.submodule {
                      options = {
                        working-dir = mkOption {
                          type = types.str;
                          default = defaults.extraction.ghostscript.working-dir;
                          description = "Directory where the extraction processes can put their temp files";
                        };
                        command = mkOption {
                          type = types.submodule {
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
                          };
                          default = defaults.extraction.ghostscript.command;
                          description = "The system command";
                        };
                      };
                    };
                    default = defaults.extraction.ghostscript;
                    description = "The ghostscript command.";
                  };
                  unpaper = mkOption {
                    type = types.submodule {
                      options = {
                        command = mkOption {
                          type = types.submodule {
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
                          };
                          default = defaults.extraction.unpaper.command;
                          description = "The system command";
                        };
                      };
                    };
                    default = defaults.extraction.unpaper;
                    description = "The unpaper command.";
                  };
                  tesseract = mkOption {
                    type = types.submodule {
                      options = {
                        command = mkOption {
                          type = types.submodule {
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
                          };
                          default = defaults.extraction.tesseract.command;
                          description = "The system command";
                        };
                      };
                    };
                    default = defaults.extraction.tesseract;
                    description = "The tesseract command.";
                  };
                };
              };
              default = defaults.extraction.ocr;
              description = "";
            };
          };
        };
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

      text-analysis = mkOption {
        type = types.submodule {
          options = {
            max-length = mkOption {
              type = types.int;
              default = defaults.text-analysis.max-length;
              description = ''
                Maximum length of text to be analysed.

                All text to analyse must fit into RAM. A large document may take
                too much heap. Also, most important information is at the
                beginning of a document, so in most cases the first two pages
                should suffice. Default is 10000, which are about 2-3 pages
                (a rough guess).
              '';
            };
            working-dir = mkOption {
              type = types.str;
              default = defaults.text-analysis.working-dir;
              description = ''
                A working directory for the analyser to store temporary/working
                files.
              '';
            };

            nlp = mkOption {
              type = types.submodule {
                options = {
                  mode = mkOption {
                    type = types.str;
                    default = defaults.text-analysis.nlp.mode;
                    description = ''
                      The mode for configuring NLP models:

                      1. full – builds the complete pipeline
                      2. basic - builds only the ner annotator
                      3. regexonly - matches each entry in your address book via regexps
                      4. disabled - doesn't use any stanford-nlp feature

                      The full and basic variants rely on pre-build language models
                      that are available for only 3 lanugages at the moment: German,
                      English, French and Spanish.

                      Memory usage varies greatly among the languages. German has
                      quite large models, that require about 1G heap. So joex should
                      run with -Xmx1400M at least when using mode=full.

                      The basic variant does a quite good job for German and
                      English. It might be worse for French, always depending on the
                      type of text that is analysed. Joex should run with about 600M
                      heap, here again lanugage German uses the most.

                      The regexonly variant doesn't depend on a language. It roughly
                      works by converting all entries in your addressbook into
                      regexps and matches each one against the text. This can get
                      memory intensive, too, when the addressbook grows large. This
                      is included in the full and basic by default, but can be used
                      independently by setting mode=regexner.

                      When mode=disabled, then the whole nlp pipeline is disabled,
                      and you won't get any suggestions. Only what the classifier
                      returns (if enabled).
                    '';
                  };

                  max-due-date-years = mkOption {
                    type = types.int;
                    default = defaults.processing.max-due-date-years;
                    description = ''
                      Restricts proposalsfor due dates. Only dates earlier than this
                      number of years in the future are considered.
                    '';
                  };

                  clear-interval = mkOption {
                    type = types.str;
                    default = defaults.text-analysis.nlp.clear-interval;
                    description = ''
                      Idle time after which the NLP caches are cleared to free
                      memory. If <= 0 clearing the cache is disabled.
                    '';
                  };

                  regex-ner = mkOption {
                    type = types.submodule {
                      options = {
                        max-entries = mkOption {
                          type = types.int;
                          default = defaults.text-analysis.regex-ner.max-entries;
                          description = ''
                            Whether to enable custom NER annotation. This uses the
                            address book of a collective as input for NER tagging (to
                            automatically find correspondent and concerned entities). If
                            the address book is large, this can be quite memory
                            intensive and also makes text analysis much slower. But it
                            improves accuracy and can be used independent of the
                            lanugage. If this is set to 0, it is effectively disabled
                            and NER tagging uses only statistical models (that also work
                            quite well, but are restricted to the languages mentioned
                            above).

                            Note, this is only relevant if nlp-config.mode is not
                            "disabled".
                          '';
                        };
                        file-cache-time = mkOption {
                          type = types.str;
                          default = defaults.text-analysis.ner-file-cache-time;
                          description = ''
                            The NER annotation uses a file of patterns that is derived from
                            a collective's address book. This is is the time how long this
                            file will be kept until a check for a state change is done.
                          '';
                        };
                      };
                    };
                    default = defaults.text-analysis.nlp.regex-ner;
                    description = "";
                  };
                };
              };
              default = defaults.text-analysis.nlp;
              description = "Configure NLP";
            };

            classification = mkOption {
              type = types.submodule {
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    default = defaults.text-analysis.classification.enabled;
                    description = ''
                      Whether to enable classification globally. Each collective can
                      decide to disable it. If it is disabled here, no collective
                      can use classification.
                    '';
                  };
                  item-count = mkOption {
                    type = types.int;
                    default = defaults.text-analysis.classification.item-count;
                    description = ''
                      If concerned with memory consumption, this restricts the
                      number of items to consider. More are better for training. A
                      negative value or zero means no train on all items.
                    '';
                  };
                  classifiers = mkOption {
                    type = types.listOf types.attrs;
                    default = defaults.text-analysis.classification.classifiers;
                    description = ''
                      These settings are used to configure the classifier. If
                      multiple are given, they are all tried and the "best" is
                      chosen at the end. See
                      https://nlp.stanford.edu/nlp/javadoc/javanlp/edu/stanford/nlp/classify/ColumnDataClassifier.html
                      for more info about these settings. The settings here yielded
                      good results with *my* dataset.
                    '';
                  };
                };
              };
              default = defaults.text-analysis.classification;
              description = ''
                Settings for doing document classification.

                This works by learning from existing documents. A collective can
                specify a tag category and the system will try to predict a tag
                from this category for new incoming documents.

                This requires a satstical model that is computed from all
                existing documents. This process is run periodically as
                configured by the collective. It may require a lot of memory,
                depending on the amount of data.

                It utilises this NLP library: https://nlp.stanford.edu/.
              '';
            };
          };
        };
        default = defaults.text-analysis;
        description = "Settings for text analysis";
      };

      convert = mkOption {
        type = types.submodule {
          options = {
            chunk-size = mkOption {
              type = types.int;
              default = defaults.convert.chunk-size;
              description = ''
                The chunk size used when storing files. This should be the same
                as used with the rest server.
              '';
            };
            converted-filename-part = mkOption {
              type = types.str;
              default = defaults.convert.converted-filename-part;
              description = ''
                A string used to change the filename of the converted pdf file.
                If empty, the original file name is used for the pdf file ( the
                extension is always replaced with `pdf`).
              '';
            };

            max-image-size = mkOption {
              type = types.int;
              default = defaults.convert.max-image-size;
              description = ''
                When reading images, this is the maximum size. Images that are
                larger are not processed.
              '';
            };
            markdown = mkOption {
              type = types.submodule {
                options = {
                  internal-css = mkOption {
                    type = types.str;
                    default = defaults.convert.markdown.internal-css;
                    description = ''
                      The CSS that is used to style the resulting HTML.
                    '';
                  };
                };
              };
              default = defaults.convert.markdown;
              description = ''
                Settings when processing markdown files (and other text files)
                to HTML.

                In order to support text formats, text files are first converted
                to HTML using a markdown processor. The resulting HTML is then
                converted to a PDF file.
              '';
            };
            html-converter = mkOption {
              type = types.enum ["wkhtmlpdf" "weasyprint"];
              default = "weasyprint";
              description = "Which tool to use for converting html to pdfs";
            };
            wkhtmlpdf = mkOption {
              type = types.submodule {
                options = {
                  working-dir = mkOption {
                    type = types.str;
                    default = defaults.convert.wktmlpdf.working-dir;
                    description = "Directory where the conversion processes can put their temp files";
                  };
                  command = mkOption {
                    type = types.submodule {
                      options = {
                        program = mkOption {
                          type = types.str;
                          default = defaults.convert.wkhtmlpdf.command.program;
                          description = "The path to the executable.";
                        };
                        args = mkOption {
                          type = types.listOf types.str;
                          default = defaults.convert.wkhtmlpdf.command.args;
                          description = "The arguments to the program";
                        };
                        timeout = mkOption {
                          type = types.str;
                          default = defaults.convert.wkhtmlpdf.command.timeout;
                          description = "The timeout when executing the command";
                        };
                      };
                    };
                    default = defaults.convert.wkhtmlpdf.command;
                    description = "The system command";
                  };
                };
              };
              default = defaults.convert.wkhtmlpdf;
              description = ''
                To convert HTML files into PDF files, the external tool
                wkhtmltopdf is used.
              '';
            };
            weasyprint = mkOption {
              type = types.submodule {
                options = {
                  working-dir = mkOption {
                    type = types.str;
                    default = defaults.convert.weasyprint.working-dir;
                    description = "Directory where the conversion processes can put their temp files";
                  };
                  command = mkOption {
                    type = types.submodule {
                      options = {
                        program = mkOption {
                          type = types.str;
                          default = defaults.convert.weasyprint.command.program;
                          description = "The path to the executable.";
                        };
                        args = mkOption {
                          type = types.listOf types.str;
                          default = defaults.convert.weasyprint.command.args;
                          description = "The arguments to the program";
                        };
                        timeout = mkOption {
                          type = types.str;
                          default = defaults.convert.weasyprint.command.timeout;
                          description = "The timeout when executing the command";
                        };
                      };
                    };
                    default = defaults.convert.weasyprint.command;
                    description = "The system command";
                  };
                };
              };
              default = defaults.convert.weasyprint;
              description = ''
                To convert HTML files into PDF files, the external tool
                weasyprint is used.
              '';
            };
            tesseract = mkOption {
              type = types.submodule {
                options = {
                  working-dir = mkOption {
                    type = types.str;
                    default = defaults.convert.tesseract.working-dir;
                    description = "Directory where the conversion processes can put their temp files";
                  };
                  command = mkOption {
                    type = types.submodule {
                      options = {
                        program = mkOption {
                          type = types.str;
                          default = defaults.convert.tesseract.command.program;
                          description = "The path to the executable.";
                        };
                        args = mkOption {
                          type = types.listOf types.str;
                          default = defaults.convert.tesseract.command.args;
                          description = "The arguments to the program";
                        };
                        timeout = mkOption {
                          type = types.str;
                          default = defaults.convert.tesseract.command.timeout;
                          description = "The timeout when executing the command";
                        };
                      };
                    };
                    default = defaults.convert.tesseract.command;
                    description = "The system command";
                  };
                };
              };
              default = defaults.convert.tesseract;
              description = ''
                To convert image files to PDF files, tesseract is used. This
                also extracts the text in one go.
              '';
            };
            unoconv = mkOption {
              type = types.submodule {
                options = {
                  working-dir = mkOption {
                    type = types.str;
                    default = defaults.convert.unoconv.working-dir;
                    description = "Directory where the conversion processes can put their temp files";
                  };
                  command = mkOption {
                    type = types.submodule {
                      options = {
                        program = mkOption {
                          type = types.str;
                          default = defaults.convert.unoconv.command.program;
                          description = "The path to the executable.";
                        };
                        args = mkOption {
                          type = types.listOf types.str;
                          default = defaults.convert.unoconv.command.args;
                          description = "The arguments to the program";
                        };
                        timeout = mkOption {
                          type = types.str;
                          default = defaults.convert.unoconv.command.timeout;
                          description = "The timeout when executing the command";
                        };
                      };
                    };
                    default = defaults.convert.unoconv.command;
                    description = "The system command";
                  };
                };
              };
              default = defaults.convert.unoconv;
              description = ''
                To convert "office" files to PDF files, the external tool
                unoconv is used. Unoconv uses libreoffice/openoffice for
                converting. So it supports all formats that are possible to read
                with libreoffice/openoffic.

                Note: to greatly improve performance, it is recommended to start
                a libreoffice listener by running `unoconv -l` in a separate
                process.
              '';
            };

            ocrmypdf = mkOption {
              type = types.submodule {
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    default = defaults.convert.ocrmypdf.enabled;
                    description = "Whether to use ocrmypdf to convert pdf to pdf/a.";
                  };
                  working-dir = mkOption {
                    type = types.str;
                    default = defaults.convert.ocrmypdf.working-dir;
                    description = "Directory where the conversion processes can put their temp files";
                  };
                  command = mkOption {
                    type = types.submodule {
                      options = {
                        program = mkOption {
                          type = types.str;
                          default = defaults.convert.ocrmypdf.command.program;
                          description = "The path to the executable.";
                        };
                        args = mkOption {
                          type = types.listOf types.str;
                          default = defaults.convert.ocrmypdf.command.args;
                          description = "The arguments to the program";
                        };
                        timeout = mkOption {
                          type = types.str;
                          default = defaults.convert.ocrmypdf.command.timeout;
                          description = "The timeout when executing the command";
                        };
                      };
                    };
                    default = defaults.convert.ocrmypdf.command;
                    description = "The system command";
                  };
                };
              };
              default = defaults.convert.ocrmypdf;
              description = ''
                The tool ocrmypdf can be used to convert pdf files to pdf files
                in order to add extracted text as a separate layer. This makes
                image-only pdfs searchable and you can select and copy/paste the
                text. It also converts pdfs into pdf/a type pdfs, which are best
                suited for archiving. So it makes sense to use this even for
                text-only pdfs.

                It is recommended to install ocrympdf, but it also is optional.
                If it is enabled but fails, the error is not fatal and the
                processing will continue using the original pdf for extracting
                text. You can also disable it to remove the errors from the
                processing logs.

                The `--skip-text` option is necessary to not fail on "text" pdfs
                (where ocr is not necessary). In this case, the pdf will be
                converted to PDF/A.
              '';
            };
          };
        };
        default = defaults.convert;
        description = ''
          Configuration for converting files into PDFs.

          Most of it is delegated to external tools, which can be configured
          below. They must be in the PATH environment or specify the full
          path below via the `program` key.
        '';
      };
      files = mkOption {
        type = types.submodule {
          options = {
            chunk-size = mkOption {
              type = types.int;
              default = defaults.files.chunk-size;
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
              default = defaults.files.valid-mime-types;
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
        default = defaults.files;
        description = "Settings for how files are stored.";
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

                Currently the SOLR search platform is supported.
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

            migration = mkOption {
              type = types.submodule {
                options = {
                  index-all-chunk = mkOption {
                    type = types.int;
                    default = defaults.full-text-search.migration.index-all-chunk;
                    description = ''
                      Chunk size to use when indexing data from the database. This
                      many attachments are loaded into memory and pushed to the
                      full-text index.
                    '';
                  };
                };
              };
              default = defaults.full-text-search.migration;
              description = "Settings for running the index migration tasks";
            };
          };
        };
        default = defaults.full-text-search;
        description = "Configuration for full-text search.";
      };
      addons = mkOption {
        type = types.submodule {
          options = {
            working-dir = mkOption {
              type = types.str;
              default = defaults.addons.working-dir;
              description = "Working directory";
            };
            cache-dir = mkOption {
              type = types.str;
              default = defaults.addons.cache-dir;
              description = "Cache directory";
            };
            executor-config = mkOption {
              type = types.submodule {
                options = {
                  runner = mkOption {
                    type = types.str;
                    default = defaults.addons.executor-config.runner;
                    description = "The supported runners by this joex";
                  };
                  fail-fast = mkOption {
                    type = types.bool;
                    default = defaults.addons.executor-config.fail-fast;
                    description = "";
                  };
                  run-timeout = mkOption {
                    type = types.str;
                    default = defaults.addons.executor-config.run-timeout;
                    description = "";
                  };
                  nspawn = mkOption {
                    type = types.submodule {
                      options = {
                        enabled = mkOption {
                          type = types.bool;
                          default = defaults.addons.nspawn.enabled;
                          description = "Enable to use systemd-nspawn";
                        };
                        sudo-binary = mkOption {
                          type = types.str;
                          default = defaults.addons.executor-config.nspawn.sudo-binary;
                          description = "";
                        };
                        nspawn-binary = mkOption {
                          type = types.str;
                          default = defaults.addons.executor-config.nspawn.nspawn-binary;
                          description = "";
                        };
                        container-wait = mkOption {
                          type = types.str;
                          default = defaults.addons.executor-config.nspawn.container-wait;
                          description = "";
                        };
                      };
                    };
                    default = defaults.addons.executor-config.nspawn;
                    description = "";
                  };
                  nix-runner = mkOption {
                    type = types.submodule {
                      options = {
                        nix-binary = mkOption {
                          type = types.str;
                          default = defaults.addons.executor-config.nix-runner.nix-binary;
                          description = "";
                        };
                        build-timeout = mkOption {
                          type = types.str;
                          default = defaults.addons.executor-config.nix-runner.build-timeout;
                          description = "";
                        };
                      };
                    };
                    default = defaults.addons.executor-config.nix-runner;
                    description = "";
                  };
                  docker-runner = mkOption {
                    type = types.submodule {
                      options = {
                        docker-binary = mkOption {
                          type = types.str;
                          default = defaults.addons.executor-config.docker-runner.docker-binary;
                          description = "";
                        };
                        build-timeout = mkOption {
                          type = types.str;
                          default = defaults.addons.executor-config.docker-runner.build-timeout;
                          description = "";
                        };
                      };
                    };
                    default = defaults.addons.executor-config.docker-runner;
                    description = "";
                  };
                };
              };
              default = defaults.addons.executor-config;
              description = "";
            };
          };
        };
        default = defaults.addons;
        description = "Addon executor config";
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
  config = mkIf config.services.docspell-joex.enable {
    users.users."${user}" = mkIf (cfg.runAs == null) {
      name = user;
      isSystemUser = true;
      createHome = true;
      home = "/var/docspell";
      description = "Docspell user";
      group = user;
    };
    users.groups."${user}" = mkIf (cfg.runAs == null) {};

    environment.etc."docspell-joex.conf" = mkIf (cfg.configFile == null) {
      text = ''
        {"docspell": {"joex":
          ${builtins.toJSON (lib.recursiveUpdate declared_config cfg.extraConfig)}
        }}
      '';
      user = user;
      group = user;
      mode = "0400";
    };

    # Setting up a unoconv listener to improve conversion performance
    systemd.services.unoconv = let
      cmd = "${pkgs.unoconv}/bin/unoconv --listener -v";
    in {
      description = "Unoconv Listener";
      after = ["networking.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Restart = "always";
      };
      script = "${pkgs.su}/bin/su -s ${pkgs.bash}/bin/sh ${user} -c \"${cmd}\"";
    };

    systemd.services.docspell-joex = let
      args = builtins.concatStringsSep " " cfg.jvmArgs;
      configFile = if cfg.configFile == null
        then "/etc/docspell-joex.conf"
        else "${cfg.configFile}";
      cmd = "${lib.getExe' cfg.package "docspell-joex"} ${args} -- ${configFile}";
      waitTarget =
        if cfg.waitForTarget != null
        then [cfg.waitForTarget]
        else [];
    in {
      description = "Docspell Joex";
      after = ["networking.target"] ++ waitTarget;
      wantedBy = ["multi-user.target"];
      path = [pkgs.gawk];

      script = "${pkgs.su}/bin/su -s ${pkgs.bash}/bin/sh ${user} -c \"${cmd}\"";
    };
  };
}
