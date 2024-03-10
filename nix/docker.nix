{
  dockerTools,
  busybox,
  cacert,
  wget,
  unpaper,
  ghostscript,
  ocrmypdf,
  tesseract4,
  python3Packages,
  unoconv,
  docspell-restserver,
  docspell-joex,
}: let
  mkImage = {
    name,
    port,
    pkg,
    tools,
  }:
    dockerTools.buildLayeredImage {
      inherit name;
      created = "now";
      contents =
        [
          busybox
          cacert
          wget
          pkg
        ]
        ++ tools;

      extraCommands = "mkdir -m 0777 tmp";

      #https://github.com/moby/docker-image-spec/blob/main/spec.md#image-json-description
      config = {
        Entrypoint = ["bin/${name}" "-Dconfig.file="];
        #Cmd = ["bin/${name}" "-Dconfig.file="];
        ExposedPorts = {
          "${builtins.toString port}/tcp" = {};
        };
        Env = [
          "PATH=/bin"
          "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
        ];
        Healthcheck = {
          Test = [
            "CMD"
            "wget"
            "--spider"
            "http://localhost:${builtins.toString port}/api/info/version"
          ];
          Interval = 60000000000; #1min
          Timeout = 10000000000; #10s
          Retries = 2;
          StartInterval = 10000000000;
        };
        Labels = {
          #https://github.com/microscaling/microscaling/blob/55a2d7b91ce7513e07f8b1fd91bbed8df59aed5a/Dockerfile#L22-L33
          "org.label-schema.vcs-ref" = "v${pkg.version}";
          "org.label-schema.vcs-url" = "https://github.com/eikek/docspell";
        };
      };
      tag = "v${pkg.version}";
    };
in {
  docspell-restserver = mkImage {
    name = "docspell-restserver";
    port = 7880;
    pkg = docspell-restserver;
    tools = [];
  };
  docspell-joex = mkImage {
    name = "docspell-joex";
    port = 7878;
    pkg = docspell-joex;
    tools = [unpaper ghostscript ocrmypdf tesseract4 python3Packages.weasyprint unoconv];
  };
}
