{ lib, rustPlatform, pkg-config, openssl, ... }:

rustPlatform.buildRustPackage {
  pname = "bobert";
  version = "0.3.0";
  src = lib.cleanSource ../.;

  cargoLock.lockFile = ../Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];
}