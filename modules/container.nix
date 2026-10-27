{ pkgs, runtimeModule }:
let
  image = pkgs.dockerTools.buildLayeredImage {
    name = "comfyui-nix-flake";
    tag = "latest";
    contents = [
      pkgs.comfyui
      pkgs.bash
      pkgs.coreutils
      pkgs.cacert
      pkgs.fakeNss
      pkgs.python3
      pkgs.comfyui.pythonEnv
      pkgs.nix
      pkgs.git
      pkgs.nushell
      pkgs.stdenv.cc.cc.lib
      pkgs.glibc
      pkgs.glibc.bin
      pkgs.uv
      runtimeModule.downloader
      runtimeModule.profileList
    ];
    extraCommands = ''
      mkdir -p $out/sbin
      ln -s ${pkgs.glibc.bin}/bin/ldconfig $out/sbin/ldconfig
    '';
    config = {
      Cmd = [ "${pkgs.coreutils}/bin/sleep" "infinity" ];
      Env = [
        "HOME=/workspace/home"
        "COMFYUI_WORKSPACE=/workspace"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:/usr/lib/x86_64-linux-gnu"
      ];
      ExposedPorts = { "8188/tcp" = { }; };
      WorkingDir = "/workspace";
    };
  };
in
{
  packages = {
    container = image;
  };
}
