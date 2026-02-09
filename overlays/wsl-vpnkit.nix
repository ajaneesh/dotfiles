_final: prev: {

  wsl-vpnkit = prev.stdenv.mkDerivation rec {
    pname = "wsl-vpnkit";
    version = "0.4.1";

    src = prev.fetchurl {
      url = "https://github.com/sakai135/wsl-vpnkit/releases/download/v${version}/wsl-vpnkit.tar.gz";
      sha256 = "sha256-UJ73bm/A1NlFJHsI8yPeWzTGx84LVzdmgOuK1+OnTtU=";
    };

    # Don't try to unpack automatically - we do it manually with tar
    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib/wsl-vpnkit

      # Extract specific files from tarball (matching the official instructions)
      tar --strip-components=1 -xf $src \
          app/wsl-vpnkit \
          app/wsl-gvproxy.exe \
          app/wsl-vm \
          app/wsl-vpnkit.service

      # Install the main script
      cp wsl-vpnkit $out/bin/
      chmod +x $out/bin/wsl-vpnkit

      # Install the binaries
      cp wsl-gvproxy.exe $out/lib/wsl-vpnkit/
      cp wsl-vm $out/lib/wsl-vpnkit/
      chmod +x $out/lib/wsl-vpnkit/wsl-vm

      # Install the systemd service file
      cp wsl-vpnkit.service $out/lib/wsl-vpnkit/

      runHook postInstall
    '';

    meta = with prev.lib; {
      description = "Route WSL traffic through Windows VPN";
      homepage = "https://github.com/sakai135/wsl-vpnkit";
      license = licenses.mit;
      platforms = [ "x86_64-linux" ];
    };
  };
}
