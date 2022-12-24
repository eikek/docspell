# NOTE: modulesPath and imports are taken from nixpkgs#59219
{ modulesPath, pkgs, lib, ... }: {
  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];
  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  services.docspell-restserver = {
    openid = lib.mkForce [ ];
    backend = lib.mkForce {
      signup = {
        mode = "open";
      };
    };
  };

  # Otherwise oomkiller kills docspell
  virtualisation.memorySize = 2048;

  virtualisation.forwardPorts = [
    # SSH
    { from = "host"; host.port = 64022; guest.port = 22; }
    # Docspell
    { from = "host"; host.port = 64080; guest.port = 7880; }
  ];

}
