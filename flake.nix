{
  description = "SentinelOne for NixOS";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      package = pkgs.callPackage ./sentinelone.nix { };
    in
    {
      packages.${system} = {
        sentinelone = package;
      };

      overlays = {
        default = final: prev: {
          sentinelone = package;
        };
      };

      defaultPackage.${system} = self.packages.${system}.sentinelone;

      nixosModules = {
        sentinelone = {
          imports = [
            ./module.nix
          ];
        };
      };
    };

}
