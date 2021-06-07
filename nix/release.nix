rec {
  cfg = {
    v0_23_0 = rec {
      version = "0.23.0";
      server = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-restserver-${version}.zip";
        sha256 = "1sd4r6358kf3nb0x1ypw77a1p17984kwdbjijzkyvvw2757w7rig";
      };
      joex = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-joex-${version}.zip";
        sha256 = "0n7ig7xk2in655iqs92ylvpchgysbxlfq3vwz296ch8pxp48p49n";
      };
      tools = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-tools-${version}.zip";
        sha256 = "1jqiva0p929kbcy6k6pxzlgmxfjrcbvqpwhdg0wyxd35k97gww6l";
      };
    };
    v0_22_0 = rec {
      version = "0.22.0";
      server = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-restserver-${version}.zip";
        sha256 = "1lysbqc62c2ijqg948wh882b6609mhal9n4ab9y4xjs788lfvd7h";
      };
      joex = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-joex-${version}.zip";
        sha256 = "0g5ajkrsnbdig0hw5nz1g75ghvds6f2389zy2ccs4zfjws6xp1nr";
      };
      tools = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-tools-${version}.zip";
        sha256 = "00n9z2z06hr431xascpxmb6vn5lc2a3hz4p2ap3zc1nbkkdwmkh2";
      };
    };
    v0_21_0 = rec {
      version = "0.21.0";
      server = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-restserver-${version}.zip";
        sha256 = "1bk904wsyfv78cgbf0srk0jzm2qd7ycz2fxci75s7dv0g3r7cas0";
      };
      joex = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-joex-${version}.zip";
        sha256 = "0b05qpshmigwf4swixwxd1nff639yvbbjwn8s9aj7yi9zrc5wpj6";
      };
      tools = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-tools-${version}.zip";
        sha256 = "1h2b2pf1zi811yasmfxnb6nnxysbcvmxlh1b0iyh9hmkh3pi1v7x";
      };
    };
    v0_20_0 = rec {
      version = "0.20.0";
      server = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-restserver-${version}.zip";
        sha256 = "1kiczs8z4j8m00w1yqirsnnjyka6knc3i6laxrb93z64n164gdwz";
      };
      joex = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-joex-${version}.zip";
        sha256 = "1lvvp2irgfbmfrqg8y23n07qwx16q8666b1ywrka84fv6c0zrig9";
      };
      tools = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-tools-${version}.zip";
        sha256 = "1nnvn1gwvv6i3f6wpckm8l8hagj87vmfp70ykpxndk5i1i2nyfay";
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
  currentPkg = pkg cfg.v0_23_0;
  module-joex = ./module-joex.nix;
  module-restserver = ./module-server.nix;
  module-consumedir = ./module-consumedir.nix;
  modules = [ module-joex
              module-restserver
              module-consumedir
            ];
}
