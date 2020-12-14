{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      hs = pkgs.haskellPackages;

      pkg = hs.callCabal2nix "redirector" ./. {};
      docker = pkgs.dockerTools.buildImage {
        name = "pnotequalnp/redirector";
        tag = "0.1.0.0";
        contents = [ pkg ];
        config.Cmd = [ "redirector" ];
      };
    in {
      defaultPackage = pkg;
      packages = { inherit pkg docker; };
      devShell = pkg.env.overrideAttrs (super: {
        nativeBuildInputs = with pkgs; super.nativeBuildInputs ++ [
          hs.cabal-install
          postgresql
          zlib
        ];
      });
    }
  );
}
