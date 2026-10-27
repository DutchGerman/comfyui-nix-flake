{ pkgs }:
let
  downloaderPython = pkgs.python3.withPackages (pythonPackages: [
    pythonPackages.huggingface-hub
    pythonPackages.hf-xet
  ]);
  downloader = pkgs.writeShellApplication {
    name = "download-comfyui-models";
    runtimeInputs = [ downloaderPython ];
    text = ''
      export HF_XET_HIGH_PERFORMANCE=1
      exec ${downloaderPython}/bin/python ${../runtime/download-models.py} "$@"
    '';
  };
  comfyuiPython = pkgs.comfyui.pythonEnv;
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
    comfyuiPython
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
