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
      pkgs.nix
      pkgs.git
      pkgs.nushell
      runtimeModule.downloader
      runtimeModule.profileList
    ];
    config = {
      Cmd = [ "${pkgs.coreutils}/bin/sleep" "infinity" ];
      Env = [
        "HOME=/workspace/home"
        "COMFYUI_WORKSPACE=/workspace"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu"
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
