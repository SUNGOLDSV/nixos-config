{ swift-flake, ... }: final: prev: {
  soulver-cpp = prev.stdenv.mkDerivation {
    pname = "soulver-cpp";
    version = "git-main";

    src = prev.fetchFromGitHub {
      owner = "vicinaehq";
      repo = "soulver-cpp";
      rev = "main";
      hash = "sha256-/1PA3IUZK1Wi8ienJsBnqrcry8LR8RvU5ruLwdZeAKk=";
    };

    nativeBuildInputs = [
      swift-flake.packages.${prev.stdenv.hostPlatform.system}.swift
      prev.cmake
      prev.ninja
      prev.pkg-config
      prev.autoPatchelfHook
    ];

    buildInputs = [
      prev.nlohmann_json
      prev.libxml2
      prev.curl
      prev.libz
      prev.openssl
      prev.stdenv.cc.cc.lib # for autoPatchelfHook
    ];

    prePatch = ''
      export VENDOR_DIR=$(pwd)/swift/Vendor/SoulverCore-linux
      chmod +w $VENDOR_DIR/libSoulverCoreDynamic.so
    '';

    preConfigure = ''
      export HOME=$TMPDIR
      export XDG_CACHE_HOME=$TMPDIR/.cache
      export SWIFT_MODULE_CACHE_PATH=$TMPDIR/swift-module-cache
      mkdir -p $SWIFT_MODULE_CACHE_PATH

      # We wrap the swift build command in CMakeLists.txt to unset Nix stdenv wrapper vars
      # so that the swift-flake wrapper script falls back to its perfectly bundled clang/binutils
      # which already has all the correct paths for glibc and its module map.
      sed -i "s|swift build -c release|env -u NIX_CC -u NIX_CC_WRAPPER_FLAGS_SET_${prev.stdenv.hostPlatform.config} -u NIX_BINTOOLS_WRAPPER_FLAGS_SET_${prev.stdenv.hostPlatform.config} -u NIX_CFLAGS_COMPILE -u NIX_CFLAGS_COMPILE_BEFORE -u NIX_LDFLAGS -u NIX_LDFLAGS_BEFORE swift build -c release|g" CMakeLists.txt
    '';

    meta = with prev.lib; {
      description = "Simple C++ bindings for the SoulverCore Swift library";
      homepage = "https://github.com/vicinaehq/soulver-cpp";
      license = licenses.unfree; # SoulverCore is closed-source
      platforms = platforms.linux;
    };
  };

  vicinae = prev.vicinae.overrideAttrs (old: {
    qtWrapperArgs = (old.qtWrapperArgs or []) ++ [
      "--prefix" "LD_LIBRARY_PATH" ":" "${final.soulver-cpp}/lib"
      "--prefix" "LD_LIBRARY_PATH" ":" "${swift-flake.packages.${prev.stdenv.hostPlatform.system}.swift}/usr/lib/swift/linux"
      "--prefix" "XDG_DATA_DIRS" ":" "${final.soulver-cpp}/share"
    ];
  });
}
