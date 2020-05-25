rec {
  cfg = {
    v0_6_0 = rec {
      version = "0.6.0";
      server = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-restserver-${version}.zip";
        sha256 = "1mh8f1hkhh3gy5bwvzxb2kyr7v169w59448pi67q4d49kffk3wl3";
      };
      joex = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-joex-${version}.zip";
        sha256 = "0p1jjaz19sajvzf750mav4h47q0a79p8555irbd4hpv3i8fpasnb";
      };
      tools = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-tools-${version}.zip";
        sha256 = "1yh65crg8hjmmp5ql4k44ipq1aw93qfx2jkc2lbdvi8vza5xaq89";
      };
    };
    v0_5_0 = rec {
      version = "0.5.0";
      server = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-restserver-${version}.zip";
        sha256 = "1cr1x5ncl8prrp50mip17filyh2g1hq4ycjq4h4zmaj1nlvzrfy5";
      };
      joex = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-joex-${version}.zip";
        sha256 = "1pgkay99h59c2hnxhibrg8dy2j5bmlkv1hi18snccf7d304xl6w6";
      };
      tools = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-tools-${version}.zip";
        sha256 = "1bqm3bwg4n2llbsipp9ydmlkk3hv0x0jx482x4jb98x0fjyipzyy";
      };
    };
    v0_4_0 = rec {
      version = "0.4.0";
      server = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-restserver-${version}.zip";
        sha256 = "1n57rspjxwz6znjl69qp59wqyj2374h8b7d90816n0akcqmnkak4";
      };
      joex = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-joex-${version}.zip";
        sha256 = "1jrmnm5bxi7mc9gzwnrpwvgclx5qclmw78dq0pf8xljwmh6zci26";
      };
      tools = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-tools-${version}.zip";
        sha256 = "1xck4h8g0z2avvyf253039yzp5g6fahyq8mkh2bpis0f7bhrrazy";
      };
    };
    v0_3_0 = rec {
      version = "0.3.0";
      server = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-restserver-${version}.zip";
        sha256 = "0j942js8h5v7h64bsizylhf28a57y4lpwyl9nwqcg8n2vd059bz5";
      };
      joex = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-joex-${version}.zip";
        sha256 = "10rfj9ar5aj0hnis4j62k4d2d7pibgbph3qwj7mvn25p51dcfdvp";
      };
      tools = {
        url = "https://github.com/eikek/docspell/releases/download/v${version}/docspell-tools-${version}.zip";
        sha256 = "1swkmgxfg5rcs45x402gy7s1p40c4ff8hil5qvlx22p7ahwzr25m";
      };
    };
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
  currentPkg = pkg cfg.v0_6_0;
  module-joex = ./module-joex.nix;
  module-restserver = ./module-server.nix;
  module-consumedir = ./module-consumedir.nix;
  modules = [ module-joex
              module-restserver
              module-consumedir
            ];
}
