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

  tools = stdenv.mkDerivation {
    name = "docspell-tools-${cfg.version}";

    src = fetchzip cfg.tools;

    buildPhase = "true";

    installPhase = ''
      mkdir -p $out/bin
      cp $src/ds.sh $out/bin/ds
      sed -i 's,CURL_CMD="curl",CURL_CMD="${curl}/bin/curl",g' $out/bin/ds

      while read f; do
        target="ds-$(basename "$f" ".sh")"
        echo "Installing $f -> $target"
        cp "$f" "$out/bin/$target"
        sed -i 's,CURL_CMD="curl",CURL_CMD="${curl}/bin/curl",g' $out/bin/$target
        sed -i 's,INOTIFY_CMD="inotifywait",INOTIFY_CMD="${inotifyTools}/bin/inotifywait",g' $out/bin/$target
        sed -i 's,JQ_CMD="jq",JQ_CMD="${jq}/bin/jq",g' $out/bin/$target
        sed -i 's,SQLITE_CMD="sqlite3",SQLITE_CMD="${sqlite}/bin/sqlite3",g' $out/bin/$target
      done < <(find . -name "*.sh" -mindepth 2 -not -path "*webextension*")

      chmod 755 $out/bin/*
    '';

    inherit meta;
  };

}
