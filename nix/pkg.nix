cfg: {stdenv, lib, fetchzip, file, curl, inotifyTools, fetchurl, jdk11, bash, jq, sqlite}:
let
  meta = with lib; {
    description = "Docspell helps to organize and archive your paper documents.";
    homepage = https://github.com/eikek/docspell;
    license = licenses.gpl3;
    maintainers = [ maintainers.eikek ];
  };
in
{ server = stdenv.mkDerivation rec {
    name = "docspell-server-${cfg.version}";

    src = fetchzip cfg.server;

    buildInputs = [ jdk11 ];

    buildPhase = "true";

    installPhase = ''
      mkdir -p $out/{bin,docspell-restserver-${cfg.version}}
      cp -R * $out/docspell-restserver-${cfg.version}/
      cat > $out/bin/docspell-restserver <<-EOF
      #!${bash}/bin/bash
      $out/docspell-restserver-${cfg.version}/bin/docspell-restserver -java-home ${jdk11} "\$@"
      EOF
      chmod 755 $out/bin/docspell-restserver
    '';

    inherit meta;
  };

  joex = stdenv.mkDerivation rec {
    name = "docspell-joex-${cfg.version}";

    src = fetchzip cfg.joex;

    buildInputs = [ jdk11 ];

    buildPhase = "true";

    installPhase = ''
      mkdir -p $out/{bin,docspell-joex-${cfg.version}}
      cp -R * $out/docspell-joex-${cfg.version}/
      cat > $out/bin/docspell-joex <<-EOF
      #!${bash}/bin/bash
      $out/docspell-joex-${cfg.version}/bin/docspell-joex -java-home ${jdk11} "\$@"
      EOF
      chmod 755 $out/bin/docspell-joex
    '';

    inherit meta;
  };

}
