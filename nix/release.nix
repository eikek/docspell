rec {
  cfg = {
    v0_2_0 = rec {
      version = "0.2.0";
      server = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-restserver-${version}.zip";
        sha256 = "1mpyd66pcsd2q4wx9vszldqlamz9qgv6abrxh7xwzw23np61avy5";
      };
      joex = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-joex-${version}.zip";
        sha256 = "1ycfcfcv24vvkdbzvnahj500gb5l9vdls4bxq0jd1zn72p4z765f";
      };
      tools = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-tools-${version}.zip";
        sha256 = "0hd93rlnnrq8xj7knp38x1jj2mv4y5lvbcv968bzk5f1az51qsvg";
      };
    };
    v0_1_0 = rec {
      version = "0.1.0";
      server = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-restserver-${version}.zip";
        sha256 = "19bmvrk07s4gsw4dszbilfv7jns7bp20lfr0ia73xdmn5w8kdhq0";
      };
      joex = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-joex-${version}.zip";
        sha256 = "175yz0lxra0qv63xjl90hh32idm13c1k1aah2hqc0ncpx22scp5v";
      };
      tools = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-tools-${version}.zip";
        sha256 = "03w5cxylk2yfkah15qrx5cl21gfly0vwa0czglb1swsri3808rdb";
      };
    };
  };
  pkg = v: import ./pkg.nix v;
  currentPkg = pkg cfg.v0_2_0;
  module-joex = ./module-joex.nix;
  module-restserver = ./module-server.nix;
  module-consumedir = ./module-consumedir.nix;
  modules = [ module-joex
              module-restserver
              module-consumedir
            ];
}
