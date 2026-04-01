{
  description = "NixOS package and module for linux-voice-assistant";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems f;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pymicro-features = pkgs.callPackage ./pkgs/pymicro-features.nix { };
          pymicro-wakeword = pkgs.callPackage ./pkgs/pymicro-wakeword.nix {
            inherit pymicro-features;
          };
          python-mpv = pkgs.callPackage ./pkgs/python-mpv.nix { };
          linux-voice-assistant = pkgs.callPackage ./pkgs/linux-voice-assistant.nix {
            inherit pymicro-features pymicro-wakeword python-mpv;
          };
        in {
          inherit pymicro-features pymicro-wakeword python-mpv linux-voice-assistant;
          default = linux-voice-assistant;
        }
      );

      nixosModules.default = import ./module.nix { inherit self; };
      nixosModules.linux-voice-assistant = self.nixosModules.default;
    };
}
