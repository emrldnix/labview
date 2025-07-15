{
  lib,
  stdenv,
  fetchurl,

  glib,
  nss,
  nspr,
  at-spi2-atk,
  xorg,
  dbus,
  gdk-pixbuf,
  gtk3,
  pango,
  cairo,
  expat,
  xorg_sys_opengl,
  libxkbcommon,
  libgbm,
  alsa-lib,
  cups,

  libxcrypt-legacy,
  freetype,
  fontconfig,
  zlib,
  ncurses,
  readline,
  libuuid,

  libarchive,
  autoPatchelfHook,
  makeWrapper,
}:

stdenv.mkDerivation {
  pname = "labview";
  version = "2022-q3";

  src = fetchurl {
    url = "https://download.ni.com/support/softlib/labview/labview_development_system/2022%20Q3/Patches/f1/Linux/lv2022Q3_f1Patch_full-linux-mac.iso";
    hash = "sha256-tQv3fQ6PkkJ2bCFm2oZZJa2Z2NoUtdVfYDLcXhD/ae0=";
  };

  buildInputs = [
    glib
    nss
    nspr
    at-spi2-atk
    dbus
    gdk-pixbuf
    gtk3
    pango
    cairo
    expat

    xorg_sys_opengl

    libxkbcommon
    libgbm
    alsa-lib
    cups.lib


    libxcrypt-legacy
    freetype
    fontconfig
    zlib
    ncurses
    readline
    libuuid
  ] ++ (with xorg; [
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libXft
    libXt
  ]);

  nativeBuildInputs = [
    libarchive
    autoPatchelfHook
    makeWrapper
  ];

  unpackPhase = ''
    runHook preUnpack

    bsdtar -xvf "$src"

    echo "Allowing write access..."
    chmod -R +w "."

    echo "Installing main program..."
    cd "LabVIEW/Linux"
    bsdtar -xvf "LabVIEW2022Q3-Full.iso" -C "../.."
    cd "../.."
    for f in rpm/*.rpm; do bsdtar -xvf "$f"; done;

    echo "Installing addon for Control Design..."
    controlDesign="LabVIEW Add-ons/Control Design and Simulation"
    cd "$controlDesign"
    bsdtar -xvf "CD&Sim2022Q3.iso"
    chmod -R +w "./"*;
    bsdtar -xvf "Linux/lvsupport2022-cdsim-22.3.0-f0.tar.gz"
    for f in rpms/*.rpm; do bsdtar -xvf "$f" -C "../.."; done;

    echo "Installing addon for MathScript RT..."
    mathScriptRT="LabVIEW Add-ons/MathScript RT"
    cd "../../$mathScriptRT"
    bsdtar -xvf "MathScript2022Q3.iso"
    chmod -R +w "./"*;
    bsdtar -xvf "Linux/lvsupport2022-mathscriptrt-22.3.0-f0.tar.gz"
    for f in "./rpms/"*.rpm; do bsdtar -xvf "$f" -C "../.."; done;

    cd "../.."

    echo "Success!"

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{opt,etc,var,usr}
    cp -rp {opt,etc,var,usr} $out

    mv "$out/usr/sbin/"* "$out/usr/bin/"
    mv "$out/usr/lib64/"* "$out/usr/lib/"
    rmdir "$out/usr/sbin"
    rmdir "$out/usr/lib64"

    mkdir -p "$out/usr/share/licenses/LabVIEW-2022"
    cp LICENSE.txt "$out/usr/share/licenses/LabVIEW-2022/LICENSE.txt"
    cp PATENTS.txt "$out/usr/share/licenses/LabVIEW-2022/PATENTS.txt"

    mkdir -p "$out/usr/share/applications"
    sed "s,Exec.*,Exec=labview -launch "%F"," "$out/usr/local/natinst/LabVIEW-2022-64/etc/desktop/apps/natinst-labview64-2022.desktop" > "$out/usr/share/applications/natinst-labview64-2022.desktop"

    mkdir -p "$out/share/mime/packages"
    cp "$out/usr/local/natinst/LabVIEW-2022-64/etc/desktop/mime/labview.xml" "$out/usr/share/mime/packages"

    mkdir -p "$out/bin"

    echo "Adding write access for utils, rpm, deb"
    chmod -R +w utils
    chmod -R +w rpm
    chmod -R +w deb

    mv "$out/usr/local/lib64/LabVIEW-2022-64/mod_nisessmgr.so.16" "$out/usr/local/lib64/LabVIEW-2022-64/mod_nisessmgr.so.13"

    ln -s "$out/usr/local/natinst/niPythonInterface/lib64/libniPythonInterface.so.22.3.0" "$out/usr/local/natinst/niPythonInterface/lib64/libniPythonInterface.so"
    ln -s "$out/usr/local/lib64/LabVIEW-2022-64/libNILVRuntimeManager.so.22.3.1" "$out/usr/local/lib64/LabVIEW-2022-64/libNILVRuntimeManager.so"

    cp -r "$out/usr/share" "$out"
    rm -rf "$out/usr/share"

    chmod -R +w $out/usr

    patchelf --set-rpath "$out/usr/local/lib64/LabVIEW-2022-64:$out/usr/local/natinst/niPythonInterface/lib64" "$out/usr/local/natinst/LabVIEW-2022-64/labviewprofull"

    ln -s "$out/usr/local/natinst/LabVIEW-2022-64/labviewprofull" "$out/bin/labview"

    wrapProgram $out/bin/labview \
      --prefix LD_LIBRARY_PATH : "$out/usr/local/lib64/LabVIEW-2022-64:$out/usr/local/natinst/niPythonInterface/lib64" \
      --set QT_X11_NO_MITSHM 1

    runHook postInstall
  '';

  meta = {
    description = "Development system";
    license = lib.licenses.unfree;
    mainProgram = "labview";
  };
}

