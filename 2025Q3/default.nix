{
  lib,
  stdenv,
  fetchurl,

  callPackage,

  core ? callPackage ./core.nix { },
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "labview_25";
  version = "25.3.2.49161-0+f9";

  src = fetchurl {
    url = "https://download.ni.com/ni-linux-desktop/labview/2025/q3/f2/community/deb/ni-labview-2025/noble/pool/ni-labview-2025/n/ni-labview-2025-community/ni-labview-2025-community_${finalAttrs.version}_amd64.deb";
  };
})
