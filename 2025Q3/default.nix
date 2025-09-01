{
  lib,
  stdenvNoCC,
  fetchurl,

  callPackage,
  labview ? callPackage ../. { },

  dpkg,
  autoPatchelfHook,
  makeWrapper,

  xorg,
  libxext,
  libx11,
  libGLU,
  libGL,
  libgcc,

  avahi,
}:
let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);

  baseUrl = "https://download.ni.com/ni-linux-desktop/LabVIEW/2025/Q3/f2/community/deb/ni-labview-2025/noble/pool/ni-labview-2025";
  inherit (sources) version;

  mkDeb = { name, version, hash, arch ? "amd64" }: fetchurl {
    url = "${baseUrl}/${builtins.substring 0 1 name}/${name}/${name}_${version}_${arch}.deb";
    inherit hash;
  };

  depDebs = map (pkg: mkDeb (let
    extVersion = "25.3.0.49442-0+f290";
    dep = sources.deps.${pkg};
  in
    { name = pkg; } //
    (
      if builtins.isAttrs dep then
        {
          version = if (dep.internal or false) then version else dep.version or extVersion;
          hash = dep.hash or "";
        }
      else if builtins.isString dep then
        {
          version = extVersion;
          hash = dep;
        }
      else
         throw "Unexpected type: ${builtins.typeOf dep} (expected attr set or string)"
  ) // (if builtins.isAttrs dep && builtins.hasAttr "arch" dep then { inherit (dep) arch; } else {}))) (builtins.attrNames (sources.deps));
in
labview.overrideAttrs {
  pname = "labview_25";
  inherit version;

  src = mkDeb {
    name = "ni-labview-2025-community";
    inherit version;
    inherit (sources) hash;
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = with xorg; [
    libXinerama

    libxext
    libx11
    libGLU
    libGL
    libgcc

    avahi
  ];

  unpackPhase = null;

  postUnpack = ''
    # Extract our dependencies.

    echo "Extracting dependencies."
    ${lib.concatStringsSep "\n" (map (d: "dpkg-deb -x ${d} .") depDebs)}
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,etc,usr}

    cp -rp usr $out

    cp -rp ../usr $out
    cp -rp ../etc $out

    mv "$out/usr/local/natinst/LabVIEW-2025-64/resource/mod_nisessmgr.so.25" "$out/usr/local/natinst/LabVIEW-2025-64/resource/mod_nisessmgr.so.13"

    ln -s "$out/usr/local/natinst/niPythonInterface/lib64/libniPythonInterface.so.25.3.0" "$out/usr/local/natinst/niPythonInterface/lib64/libniPythonInterface.so"
    ln -s "$out/usr/local/lib64/LabVIEW-2025-64/libNILVRuntimeManager.so.25.3.0" "$out/usr/local/lib64/LabVIEW-2025-64/libNILVRuntimeManager.so"

    chmod -R +w $out/usr

    patchelf --set-rpath "$out/usr/local/lib64/LabVIEW-2025-64:$out/usr/local/natinst/niPythonInterface/lib64" "$out/usr/local/natinst/LabVIEW-2025-64/labviewcommunity"

    ln -s "$out/usr/local/natinst/LabVIEW-2025-64/labviewcommunity" "$out/bin/labview"

    wrapProgram $out/bin/labview \
      --prefix LD_LIBRARY_PATH : "$out/usr/local/lib64/LabVIEW-2025-64:$out/usr/local/natinst/niPythonInterface/lib64" \
      --set QT_X11_NO_MITSHM 1

    runHook postInstall
  '';
}
