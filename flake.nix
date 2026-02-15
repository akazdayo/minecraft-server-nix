{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    ...
  }: let
    nixosConfigurations = {
      do = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-image.nix"
          ./do-image.nix
        ];
      };
    };
  in
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        formatter = pkgs.alejandra;
        packages.do-image = nixosConfigurations.do.config.system.build.digitalOceanImage;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
          ];
        };
      }
    );
}
