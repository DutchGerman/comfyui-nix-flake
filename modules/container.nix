{ pkgs, runtimeModule }:
let
  ldconfig = pkgs.runCommand "comfyui-ldconfig" { } ''
    mkdir -p $out/sbin
    ln -s ${pkgs.glibc.bin}/bin/ldconfig $out/sbin/ldconfig
  '';
  opencvRuntimeLibraries = [
    pkgs.libxcb
    pkgs.libx11
    pkgs.libxext
    pkgs.libxrender
    pkgs.libsm
    pkgs.libice
  ];
  image = pkgs.dockerTools.buildLayeredImage {
    name = "comfyui-nix-flake";
    tag = "latest";
    contents = [
      pkgs.comfyui
      pkgs.bash
      pkgs.coreutils
      pkgs.cacert
      pkgs.fakeNss
      pkgs.comfyui.pythonEnv
      pkgs.nix
      pkgs.git
      pkgs.nushell
      pkgs.stdenv.cc.cc.lib
      pkgs.glibc
      pkgs.glibc.bin
      ldconfig
      pkgs.uv
      runtimeModule.downloader
      runtimeModule.profileList
    ] ++ opencvRuntimeLibraries;
    config = {
      Cmd = [ "${pkgs.coreutils}/bin/sleep" "infinity" ];
      Env = [
        "HOME=/tmp/comfyui-home"
        "HF_HOME=/tmp/huggingface"
        "COMFYUI_USER_DIRECTORY=/tmp/comfyui-user"
        "COMFYUI_WORKSPACE=/workspace"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath ([ pkgs.stdenv.cc.cc.lib ] ++ opencvRuntimeLibraries)}:/usr/lib/x86_64-linux-gnu"
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
