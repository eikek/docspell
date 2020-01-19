let
  currentVersion =
    let
      file = builtins.readFile ../version.sbt;
      comps = builtins.split ":=" file;
      last = builtins.head (builtins.tail (builtins.filter builtins.isString comps));
    in
      builtins.replaceStrings ["\"" "\n" " "] ["" "" ""] last;
in
rec {
  pkg = v: import ./pkg.nix v;
  currentPkg = pkg currentVersion;
  module-joex = ./module-joex.nix;
  module-restserver = ./module-server.nix;
  module-consumedir = ./module-consumedir.nix;
  modules = [ module-joex
              module-restserver
              module-consumedir
            ];
}
