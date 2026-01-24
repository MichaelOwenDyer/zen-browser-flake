{
  description = "Zen Browser";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      version = "1.18b";
      tarballs = {
        "x86_64-linux" = {
          url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-x86_64.tar.xz";
          sha256 = "sha256:02aandxdcsmayf1lblyxh0vrq3p7mfg0s4zzd72vhnp0kyl75r8z";
        };
        "aarch64-linux" = {
          url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-aarch64.tar.xz";
          sha256 = "sha256:0q5b3i9d5ps8jr7h0g2a1472sykx3xq4hc6qp0pdxpc3i616p6iv";
        };
      };
      mkZen =
        { pkgs, tarball }:
        let
          runtimeLibs =
            with pkgs;
            [
              libGL
              libGLU
              libevent
              libffi
              libjpeg
              libpng
              libstartup_notification
              libvpx
              libwebp
              stdenv.cc.cc
              fontconfig
              libxkbcommon
              zlib
              freetype
              gtk3
              libxml2
              dbus
              xcb-util-cursor
              alsa-lib
              libpulseaudio
              pango
              atk
              cairo
              gdk-pixbuf
              glib
              udev
              libva
              mesa
              libnotify
              cups
              pciutils
              ffmpeg
              libglvnd
              pipewire
            ]
            ++ (with pkgs.xorg; [
              libxcb
              libX11
              libXcursor
              libXrandr
              libXi
              libXext
              libXcomposite
              libXdamage
              libXfixes
              libXScrnSaver
            ]);
        in
        pkgs.stdenv.mkDerivation {
          inherit version;
          pname = "zen-browser";

          src = fetchTarball tarball;

          desktopSrc = ./.;

          phases = [
            "installPhase"
            "fixupPhase"
          ];

          nativeBuildInputs = [
            pkgs.makeWrapper
            pkgs.copyDesktopItems
            pkgs.wrapGAppsHook3
          ];

          installPhase = ''
            		  mkdir -p $out/bin && cp -r $src/* $out/bin
            		  install -D $desktopSrc/zen.desktop $out/share/applications/zen.desktop
            		  install -D $src/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen.png
            		'';

          fixupPhase = ''
            		  chmod 755 $out/bin/*
            		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen
            		  wrapProgram $out/bin/zen --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}" \
                                --set MOZ_LEGACY_PROFILES 1 --set MOZ_ALLOW_DOWNGRADE 1 --set MOZ_APP_LAUNCHER zen --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
            		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen-bin
            		  wrapProgram $out/bin/zen-bin --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}" \
                                --set MOZ_LEGACY_PROFILES 1 --set MOZ_ALLOW_DOWNGRADE 1 --set MOZ_APP_LAUNCHER zen --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
            		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/glxtest
            		  wrapProgram $out/bin/glxtest --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
            		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/updater
            		  wrapProgram $out/bin/updater --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
            		  patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/vaapitest
            		  wrapProgram $out/bin/vaapitest --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
            		'';

          meta.mainProgram = "zen";
        };
    in
    {
      packages = nixpkgs.lib.mapAttrs (
        system: tarball:
        let
          zen = mkZen {
            pkgs = nixpkgs.legacyPackages.${system};
            inherit tarball;
          };
        in
        {
          zen-browser = zen;
          default = zen;
        }
      ) tarballs;
    };
}
