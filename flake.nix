{
  description = "SentinelOne for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      flake-parts,
      nixpkgs,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        inputs,
        lib,
        withSystem,
        ...
      }:
      {
        imports = [
          inputs.flake-parts.flakeModules.easyOverlay
          inputs.treefmt-nix.flakeModule
        ];
        systems = [
          "x86_64-linux"
        ];
        perSystem =
          {
            config,
            pkgs,
            system,
            ...
          }:
          {
            treefmt = {
              programs.nixfmt = {
                enable = true;
                package = pkgs.nixfmt-rfc-style;
              };
              programs.mdformat.enable = true;
            };

            overlayAttrs = {
              inherit (config.packages) sentinelone;
            };

            packages = {
              sentinelone = pkgs.callPackage ./package.nix { };
            };

            checks = {
              default = self.checks.${system}.vmtest;
              vmtest = (
                import ./test.nix {
                  inherit pkgs;
                  inherit (self) nixosModules;
                }
              );
            };
          };

        flake = {
          nixosModules = {
            default = {
              imports = [
                ./module.nix
              ];
              nixpkgs.overlays = [
                self.overlays.default
              ];
            };
            sentinelone = self.nixosModules.default;
          };
        };
      }
    );

}
