{
  system ? builtins.currentSystem or "x86_64-linux",
  pkgs ? import (import ./npins).nixpkgs { inherit system; },
}:
let
  inherit (pkgs)
    callPackage
    rustPlatform
    lib
    pkg-config
    zstd
    aws-lc
    xz
    ;

  hyperscan = callPackage ./nix/hyperscan.nix { };
in
rustPlatform.buildRustPackage {
  pname = "grep-hydra";
  version = "0.1.0";

  __strucutredAttrs = true;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.toml
      ./Cargo.lock
      ./src
      ./test-data
    ];
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    zstd
    aws-lc
    hyperscan
    xz
  ];

  env = {
    CARGO_PROFILE_RELEASE_LTO = "thin";
    CARGO_PROFILE_RELEASE_CODEGEN_UNITS = 1;
    ZSTD_SYS_USE_PKG_CONFIG = true;
    AWS_LC_SYS_USE_SYSTEM = true;
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "harmonia-file-core-3.3.0" = "sha256-KdCp0zdmoEptO9W/xhm9SpMVjqy3c96hVcsWPxDctqg=";
    };
  };

  meta = {
    license = lib.licenses.blueOak100;
    mainProgram = "grep-hydra";
  };
}
