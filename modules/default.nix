{ inputs, ... }:
{
  perSystem =
    { pkgs, self', ... }:
    let
      profiles = import ../profiles { inherit pkgs; };
      composed = profiles.compose profiles.selected;
      manifest = builtins.toJSON composed.models;
      workflows = pkgs.linkFarm "comfyui-workflows" (
        map (workflow: {
          name = workflow.name;
          path = workflow.source;
        }) composed.workflows
      );
      customNodes = pkgs.linkFarm "comfyui-custom-nodes" (
        map (customNode: {
          name = customNode.name;
          path = customNode.source;
        }) composed.customNodes
      );
      downloadModels = pkgs.writeShellApplication {
        name = "download-comfyui-models";
        runtimeInputs = [ pkgs.python3 ];
        text = ''
          exec python3 ${../runtime/download-models.py} "$@"
        '';
      };
      entrypoint = pkgs.writeShellApplication {
        name = "comfyui-entrypoint";
        runtimeInputs = [ pkgs.bash pkgs.coreutils pkgs.comfyui downloadModels ];
        text = ''
          set -euo pipefail

          workspace="''${COMFYUI_WORKSPACE:-/workspace}"
          mkdir -p "$workspace/models" "$workspace/workflows" "$workspace/custom_nodes" "$workspace/input" "$workspace/output"

          download-comfyui-models \
            --manifest ${pkgs.writeText "models.json" manifest} \
            --root "$workspace/models"

          cp -rn ${workflows}/. "$workspace/workflows/"
          cp -rn ${customNodes}/. "$workspace/custom_nodes/"

          exec comfyui \
            --listen "''${COMFYUI_LISTEN:-0.0.0.0}" \
            --port "''${COMFYUI_PORT:-8188}" \
            --base-directory "$workspace" \
            "$@"
        '';
      };
      image = pkgs.dockerTools.buildLayeredImage {
        name = "comfyui-nix-flake";
        tag = "latest";
        contents = [
          pkgs.comfyui
          pkgs.bash
          pkgs.coreutils
          pkgs.cacert
          pkgs.python3
          downloadModels
          entrypoint
        ];
        config = {
          Cmd = [ "${entrypoint}/bin/comfyui-entrypoint" ];
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
      packages.default = pkgs.comfyui;
      packages.comfyui = pkgs.comfyui;
      packages.models = pkgs.writeText "models.json" manifest;
      packages.workflows = workflows;
      packages.container = image;

      apps.default = {
        type = "app";
        program = "${entrypoint}/bin/comfyui-entrypoint";
      };

      formatter = pkgs.nixfmt-rfc-style;
    };
}
