{
  stdenv,
  bash,
  fetchzip,
  jdk17,
}: let
  version = "0.41.0";
  server = {
    url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-restserver-${version}.zip";
    sha256 = "sha256-JFftIzI94UNLLh96I++qFsBZhOkquPIPhNhtS2Ov8wI=";
  };
  joex = {
    url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-joex-${version}.zip";
    sha256 = "sha256-flKWjEsMd2/XT3Bu6EjFgf3lCojvLbKFDEXemP1K+/8=";
  };
in {
  docspell-restserver = stdenv.mkDerivation {
    inherit version;
    pname = "docspell-restserver";

    src = fetchzip server;
    buildInputs = [jdk17];
    buildPhase = "true";

    installPhase = ''
      mkdir -p $out/{bin,docspell-restserver-${version}}
      cp -R * $out/docspell-restserver-${version}/
      cat > $out/bin/docspell-restserver <<-EOF
      #!${bash}/bin/bash
      $out/docspell-restserver-${version}/bin/docspell-restserver -java-home ${jdk17} "\$@"
      EOF
      chmod 755 $out/bin/docspell-restserver

    '';
  };

  docspell-joex = stdenv.mkDerivation rec {
    inherit version;

    pname = "docspell-joex";

    src = fetchzip joex;

    buildInputs = [jdk17];

    buildPhase = "true";

    installPhase = ''
      mkdir -p $out/{bin,docspell-joex-${version}}
      cp -R * $out/docspell-joex-${version}/
      cat > $out/bin/docspell-joex <<-EOF
      #!${bash}/bin/bash
      $out/docspell-joex-${version}/bin/docspell-joex -java-home ${jdk17} "\$@"
      EOF
      chmod 755 $out/bin/docspell-joex
    '';
  };
}
