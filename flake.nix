{
  description = "SentinelOne for NixOS";
  outputs = { self, nixpkgs }: 
  let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in
  {
    nixosModules = {
      sentinel-one = {
        imports = [
          ./sentinelone/default.nix
        ];
      };
    };
  };
}
