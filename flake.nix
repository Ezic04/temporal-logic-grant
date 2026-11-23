{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        files = builtins.readDir ./.;
        cabalFiles = pkgs.lib.filterAttrs (n: v: v == "regular" && pkgs.lib.hasSuffix ".cabal" n) files;
        cabalFileName = builtins.head (builtins.attrNames cabalFiles);
        projectName = pkgs.lib.removeSuffix ".cabal" cabalFileName;
        hs = pkgs.haskellPackages;
        projectPackage = hs.callCabal2nix projectName ./. { };
      in
      {
        devShells.default = hs.shellFor {
          packages = p: [ projectPackage ];

          nativeBuildInputs = with pkgs; [
            cabal-install
            haskell-language-server
            hlint
          ];

          shellHook = ''
            export CABAL_DIR="$PWD/.cabal-local"
          '';
        };
      }
    );
}
