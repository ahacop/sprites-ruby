{
  description = "A Nix-flake-based Ruby development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
    nixpkgs-ruby.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-ruby,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            nixpkgs-ruby.overlays.default
          ];
        };
        rubyPkg = pkgs."ruby-4.0.1";
        isAarch64Linux = system == "aarch64-linux";
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs;
            [
              checkmake
              cmake
              curl
              gcc
              gmp
              gnumake
              libxml2
              libxslt
              libyaml
              openssl
              pkg-config
              rubyPkg
              readline
            ];

          shellHook = ''
            export LD_LIBRARY_PATH=${pkgs.gcc.cc.lib}/lib:$LD_LIBRARY_PATH
          '';
        };
      }
    );
}
