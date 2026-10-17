{ pkgs }:
let
  downloader = pkgs.writeShellApplication {
    name = "download-comfyui-models";
    runtimeInputs = [ pkgs.python3 ];
    text = ''exec python3 ${../runtime/download-models.py} "$@"'';
  };
  nixComfyScript = pkgs.writeScriptBin "nix-comfy" ''
    #!${pkgs.nushell}/bin/nu
    ${builtins.readFile ../runtime/nix-comfy.nu}
  '';
  runtimeInputs = [
    pkgs.bash
    pkgs.cacert
    pkgs.comfyui
    pkgs.coreutils
    pkgs.git
    pkgs.nix
    pkgs.nushell
    pkgs.python3
    downloader
  ];
  profileList = pkgs.symlinkJoin {
    name = "nix-comfy";
    paths = [ nixComfyScript ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/nix-comfy" \
        --prefix PATH : "${pkgs.lib.makeBinPath runtimeInputs}"
    '';
  };
in
{
  downloader = downloader;
  profileList = profileList;
  packages = {
    nix-comfy = profileList;
  };
}
