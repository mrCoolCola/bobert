{ lib, rustPlatform, pkg-config, openssl, ... }:

rustPlatform.buildRustPackage {
  pname = "bobert";
  version = "0.3.1";
  src = lib.cleanSource ../.;

  cargoLock.lockFile = ../Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl openssl.dev ];
  AWS_LC_SYS_USE_SYSTEM = "0";
}