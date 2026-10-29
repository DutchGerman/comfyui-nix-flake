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
      export HF_HUB_DISABLE_XET="''${HF_HUB_DISABLE_XET:-1}"
      if [ "$HF_HUB_DISABLE_XET" != 1 ]; then
        export HF_XET_HIGH_PERFORMANCE=1
      fi
      exec ${downloaderPython}/bin/python ${../runtime/download-models.py} "$@"
    '';
  };
  comfyuiPython = pkgs.comfyui.pythonEnv;
  nixComfyFallback = pkgs.writeText "nix-comfy-fallback.nu" (builtins.readFile ../runtime/nix-comfy.nu);
  nixComfyScript = pkgs.writeScriptBin "nix-comfy" ''
    #!${pkgs.nushell}/bin/nu
    $env.NIX_COMFY_FALLBACK = "${nixComfyFallback}"
    ${builtins.readFile ../runtime/bootstrap-comfy.nu}
  '';
  runtimeInputs = [
    pkgs.bash
    pkgs.cacert
    pkgs.comfyui
    pkgs.coreutils
    pkgs.git
    pkgs.nix
    pkgs.nushell
    comfyuiPython
    pkgs.gnutar
    pkgs.uv
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
