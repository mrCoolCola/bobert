{ lib, rustPlatform, pkg-config, openssl, cmake, perl, ... }:

rustPlatform.buildRustPackage {
  pname = "bobert";
  version = "0.3.1";
  src = lib.cleanSource ../.;

  cargoLock.lockFile = ../Cargo.lock;

  nativeBuildInputs = [ pkg-config cmake perl];
  buildInputs = [ openssl openssl.dev ];
  # stoopid aws-lc-sys compilation fixes
  dontCargoUseSystemLibs = true;
  AWS_LC_SYS_USE_SYSTEM = "0";
  AWS_LC_SYS_CMAKE_BUILDER = "1";
}