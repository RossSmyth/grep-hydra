{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ragel,
  python3,
  util-linux,
  pkg-config,
  boost,
  openssl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hyperscan";
  version = "5.4.2.1";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "hyperscan";
    tag = "v${finalAttrs.version}";
    hash = "sha256-6wfekQ4ySN+ejh8cGdFwZb2tOTYZxoZye3ROMsV4oYg=";
  };

  outputs = [
    "out"
    "dev"
  ];

  postPatch = ''
    sed -i '/examples/d' CMakeLists.txt
    substituteInPlace libhs.pc.in \
      --replace-fail "libdir=@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_LIBDIR@" "libdir=@CMAKE_INSTALL_LIBDIR@" \
      --replace-fail "includedir=@CMAKE_INSTALL_PREFIX@/@CMAKE_INSTALL_INCLUDEDIR@" "includedir=@CMAKE_INSTALL_INCLUDEDIR@"
  ''
  # CMake 4 dropped support of versions lower than 3.5,
  # versions lower than 3.10 are deprecated.
  # https://github.com/NixOS/nixpkgs/issues/445447
  + ''
    substituteInPlace CMakeLists.txt \
      --replace-fail \
        "cmake_minimum_required (VERSION 2.8.11)" \
        "cmake_minimum_required (VERSION 3.10)"
  ''
  # FAT_RUNTIME prefixes every global symbol not listed in keep.syms. Upstream
  # adds libcrypto's symbols via `cc --print-file-name`, which cannot find the
  # library in the Nix sandbox, so OpenSSL references get prefixed and fail to link.
  + ''
    substituteInPlace cmake/build_wrapper.sh \
      --replace-fail \
        'LIBCRYPTO_SO=$("$@" --print-file-name=libcrypto.so)' \
        'LIBCRYPTO_SO=${lib.getLib openssl}/lib/libcrypto${stdenv.hostPlatform.extensions.sharedLibrary}'
  ''
  # unit-hyperscan calls these internal helpers, but shared builds use
  # -fvisibility=hidden, so the test fails to link against libhs.so.
  + ''
    substituteInPlace src/database.h \
      --replace-fail \
        "void hs_db_free(void *ptr, size_t size);" \
        "HS_PUBLIC_API void hs_db_free(void *ptr, size_t size);" \
      --replace-fail \
        "void hs_db_unprotect(void *ptr, size_t size);" \
        "HS_PUBLIC_API void hs_db_unprotect(void *ptr, size_t size);"
  '';

  buildInputs = [
    boost
    openssl
  ];
  nativeBuildInputs = [
    cmake
    ragel
    python3
    util-linux
    pkg-config
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_AVX512" true)
    (lib.cmakeBool "BUILD_SHARED_LIBS" true)
  ]
  ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
    (lib.cmakeBool "FAT_RUNTIME" true)
  ];

  doCheck = true;
  checkPhase = ''
    runHook preCheck

    bin/unit-hyperscan

    runHook postCheck
  '';
})
