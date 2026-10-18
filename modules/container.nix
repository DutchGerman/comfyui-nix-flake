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
