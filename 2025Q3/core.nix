{
  lib,
  stdenv,
  fetchurl,

  dpkg,
}:
let
  version = "25.3.2.49161-0+f9";

  communityExe = fetchurl {
    url = "https://download.ni.com/ni-linux-desktop/LabVIEW/2025/Q3/f2/community/deb/ni-labview-2025/noble/pool/ni-labview-2025/l/labview-2025-community-exe/labview-2025-community-exe_${version}_amd64.deb";
    hash = "sha256-GG4MIOuPUmi8LJ14FN5EOqGNuW/lLXmcJut4qyjItS8=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "labview-core_25";
  inherit version;

  src = fetchurl {
    url = "https://download.ni.com/ni-linux-desktop/LabVIEW/2025/Q3/f2/community/deb/ni-labview-2025/noble/pool/ni-labview-2025/n/ni-labview-2025-core/ni-labview-2025-core_${finalAttrs.version}_amd64.deb";
    hash = "sha256-UqN02PjlJhdgGy12BuszeTvsXbcUOR4pd9TrnVZx5xM=";
  };

  nativeBuildInputs = [ dpkg ];

  postUnpack = ''
    dpkg-deb -x ${communityExe} exe
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''

  '';
})
