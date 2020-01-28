cfg: {stdenv, fetchzip, file, curl, inotifyTools, fetchurl, jre8_headless, bash}:
let
  meta = with stdenv.lib; {
    description = "Docspell helps to organize and archive your paper documents.";
    homepage = https://github.com/eikek/docspell;
    license = licenses.gpl3;
    maintainers = [ maintainers.eikek ];
  };
in
{ server = stdenv.mkDerivation rec {
    name = "docspell-server-${cfg.version}";

     src = fetchzip cfg.server;

    buildInputs = [ jre8_headless ];

    buildPhase = "true";

    installPhase = ''
      mkdir -p $out/{bin,docspell-restserver-${cfg.version}}
      cp -R * $out/docspell-restserver-${cfg.version}/
      cat > $out/bin/docspell-restserver <<-EOF
      #!${bash}/bin/bash
      $out/docspell-restserver-${cfg.version}/bin/docspell-restserver -java-home ${jre8_headless} "\$@"
      EOF
      chmod 755 $out/bin/docspell-restserver
    '';

    inherit meta;
  };

  joex = stdenv.mkDerivation rec {
    name = "docspell-joex-${cfg.version}";

    src = fetchzip cfg.joex;

    buildInputs = [ jre8_headless ];

    buildPhase = "true";

    installPhase = ''
      mkdir -p $out/{bin,docspell-joex-${cfg.version}}
      cp -R * $out/docspell-joex-${cfg.version}/
      cat > $out/bin/docspell-joex <<-EOF
      #!${bash}/bin/bash
      $out/docspell-joex-${cfg.version}/bin/docspell-joex -java-home ${jre8_headless} "\$@"
      EOF
      chmod 755 $out/bin/docspell-joex
    '';

    inherit meta;
  };

  tools = stdenv.mkDerivation {
    name = "docspell-tools-${cfg.version}";

    src = fetchzip cfg.tools;

    buildPhase = "true";

    installPhase = ''
      mkdir -p $out/bin
      cp $src/consumedir.sh $out/bin/
      cp $src/ds.sh $out/bin/ds
      sed -i 's,CURL_CMD="curl",CURL_CMD="${curl}/bin/curl",g' $out/bin/consumedir.sh
      sed -i 's,CURL_CMD="curl",CURL_CMD="${curl}/bin/curl",g' $out/bin/ds
      sed -i 's,INOTIFY_CMD="inotifywait",INOTIFY_CMD="${inotifyTools}/bin/inotifywait",g' $out/bin/consumedir.sh
      sed -i 's,FILE_CMD="file",FILE_CMD="${file}/bin/file",g' $out/bin/ds
      chmod 755 $out/bin/*
    '';

    inherit meta;
  };

}
