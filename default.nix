{
  lib,
  stdenv,
  fetchurl,

  libarchive,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "labview";
  version = "2022-q3";

  src = fetchurl {
    url = "https://download.ni.com/support/softlib/labview/labview_development_system/2022%20Q3/Patches/f1/Linux/lv2022Q3_f1Patch_full-linux-mac.iso";
    hash = "sha256-tQv3fQ6PkkJ2bCFm2oZZJa2Z2NoUtdVfYDLcXhD/ae0=";
  };

  nativeBuildInputs = [
    libarchive
  ];

  unpackPhase = ''
    runHook preUnpack

    bsdtar -xvf "$src"
    for f in "rpm/*.rpm"; do bsdtar -xvf "$src"; done;

    controlDesign="LabVIEW Add-ons/Control Design and Simulation"
    bsdtar -xvf "$controlDesign/CD&Sim2022Q3.iso"

    runHook postUnpack
  '';
})

