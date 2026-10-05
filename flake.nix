{
  description = "Flake for my Rust telegram bot - Bobert.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
        myApp = pkgs.callPackage ./nix/package.nix { };
      in
      {
        packages.default = myApp;
        packages.bobert = myApp;

        devShells.default = pkgs.mkShell {
          inputsFrom = [ myApp ];
          packages = [
            pkgs.pkg-config
            pkgs.rustc
            pkgs.cargo
            pkgs.openssl
            pkgs.openssl.dev
            pkgs.zlib
            pkgs.zlib.dev
            pkgs.rust-analyzer
          ];
          env = {
            PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.zlib.dev}/lib/pkgconfig";
            RUST_LOG = "debug";
          };
          shellHook = ''
            echo "Setup is done"
          '';
        };
      }
    ) // {
      nixosModules.default = { config, lib, pkgs, ... }: let
        cfg = config.services.bobert;
      in {
        imports = [ ./nix/module.nix ];
        # Прокидываем собранный пакет в модуль
        services.bobert.package = lib.mkDefault (
          self.packages.${pkgs.stdenv.hostPlatform.system}.bobert
        );
      };
    };
}