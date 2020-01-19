version: {stdenv, fetchzip, file, curl, inotifyTools, fetchurl, jre8_headless, bash}:
let
#  version = "0.2.0";
  meta = with stdenv.lib; {
    description = "Docspell helps to organize and archive your paper documents.";
    homepage = https://github.com/eikek/docspell;
    license = licenses.gpl3;
    maintainers = [ maintainers.eikek ];
  };
in
{ server = stdenv.mkDerivation rec {
    name = "docspell-server-${version}";

     src = fetchzip {
       url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-restserver-${version}.zip";
       sha256 = "1mpyd66pcsd2q4wx9vszldqlamz9qgv6abrxh7xwzw23np61avy5";
     };

    buildInputs = [ jre8_headless ];

    buildPhase = "true";

    installPhase = ''
      mkdir -p $out/{bin,program}
      cp -R * $out/program/
      cat > $out/bin/docspell-restserver <<-EOF
      #!${bash}/bin/bash
      $out/program/bin/docspell-restserver -java-home ${jre8_headless} "\$@"
      EOF
      chmod 755 $out/bin/docspell-restserver
    '';

    inherit meta;
  };

  joex = stdenv.mkDerivation rec {
    name = "docspell-joex-${version}";

     src = fetchzip {
       url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-joex-${version}.zip";
       sha256 = "1ycfcfcv24vvkdbzvnahj500gb5l9vdls4bxq0jd1zn72p4z765f";
     };

    buildInputs = [ jre8_headless ];

    buildPhase = "true";

    installPhase = ''
      mkdir -p $out/{bin,program}
      cp -R * $out/program/
      cat > $out/bin/docspell-joex <<-EOF
      #!${bash}/bin/bash
      $out/program/bin/docspell-joex -java-home ${jre8_headless} "\$@"
      EOF
      chmod 755 $out/bin/docspell-joex
    '';

    inherit meta;
  };

  tools = stdenv.mkDerivation rec {
    name = "docspell-tools-${version}";

    src = fetchzip {
      url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-tools-${version}.zip";
      sha256 = "0hd93rlnnrq8xj7knp38x1jj2mv4y5lvbcv968bzk5f1az51qsvg";
    };

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
