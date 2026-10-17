{ inputs, ... }: {
  perSystem = { pkgs, self', ... }:
    let
      profiles = import ../profiles { inherit pkgs; };
      composed = profiles.compose profiles.selected;
      manifest = builtins.toJSON composed.models;
      workflows = pkgs.linkFarm "comfyui-workflows" (map (workflow: {
        name = workflow.name;
        path = workflow.source;
      }) composed.workflows);
      inputAssets = pkgs.linkFarm "comfyui-input-assets" (map (asset: {
        name = asset.name;
        path = asset.source;
      }) composed.inputAssets);
      customNodes = pkgs.linkFarm "comfyui-custom-nodes" (map (customNode: {
        name = customNode.name;
        path = customNode.source;
      }) composed.customNodes);
      runtimeEnvironment = pkgs.lib.concatStringsSep "\n"
        (pkgs.lib.mapAttrsToList (name: value: ''
          : "''${${name}:=${pkgs.lib.escapeShellArg value}}"
          export ${name}
        '') composed.runtime.environment);
      runtimeArgs = pkgs.lib.concatMapStringsSep " " pkgs.lib.escapeShellArg
        composed.runtime.extraArgs;
      downloadModels = pkgs.writeShellApplication {
        name = "download-comfyui-models";
        runtimeInputs = [ pkgs.python3 ];
        text = ''
          exec python3 ${../runtime/download-models.py} "$@"
        '';
      };
      profilePackages = map (profile:
        let
          composedProfile = profiles.compose [ profile ];
          profileName = profile.installName or profile.name;
          profileManifest = builtins.toJSON composedProfile.models;
          profileWorkflows = pkgs.linkFarm "nix-comfy-${profileName}-workflows"
            (map (workflow: {
              name = workflow.name;
              path = workflow.source;
            }) composedProfile.workflows);
          profileInputAssets = pkgs.linkFarm "nix-comfy-${profileName}-input"
            (map (asset: {
              name = asset.name;
              path = asset.source;
            }) composedProfile.inputAssets);
          profileCustomNodes =
            pkgs.linkFarm "nix-comfy-${profileName}-custom-nodes" (map
              (customNode: {
                name = customNode.name;
                path = customNode.source;
              }) composedProfile.customNodes);
          profileResources = pkgs.linkFarm "nix-comfy-${profileName}" [
            {
              name = "models.json";
              path = pkgs.writeText "nix-comfy-${profileName}-models.json"
                profileManifest;
            }
            {
              name = "workflows";
              path = profileWorkflows;
            }
            {
              name = "input";
              path = profileInputAssets;
            }
            {
              name = "custom_nodes";
              path = profileCustomNodes;
            }
          ];
        in {
          inherit profileName profileResources;
          runtime = composedProfile.runtime;
        }) profiles.available;
      profileList = pkgs.lib.concatMapStringsSep "\n" (profile: ''
        printf '%s\n' ${pkgs.lib.escapeShellArg profile.profileName}
      '') profilePackages;
      profileNames = pkgs.lib.concatMapStringsSep " "
        (profile: pkgs.lib.escapeShellArg profile.profileName) profilePackages;
      profileCases = pkgs.lib.concatStringsSep "\n" (map (profile: ''
        ${pkgs.lib.escapeShellArg profile.profileName})
          profile=${pkgs.lib.escapeShellArg profile.profileName}
          manifest=${profile.profileResources}/models.json
          resources=${profile.profileResources}
          profileListen=${pkgs.lib.escapeShellArg profile.runtime.listen}
          profilePort=${toString profile.runtime.port}
          profileState="$workspace/.nix-comfy/$profile"
          ;;
      '') profilePackages);
      nixComfy = pkgs.writeShellApplication {
        name = "nix-comfy";
        runtimeInputs =
          [ pkgs.bash pkgs.coreutils downloadModels pkgs.comfyui ];
        text = ''
          set -euo pipefail

          workspace="''${COMFYUI_WORKSPACE:-/workspace}"
          profile=""
          manifest=""
          resources=""
          profileListen=""
          profilePort=""
          profileState=""

          case ''${1:-} in
            profiles)
              ${profileList}
              ;;
            install)
              case ''${2:-} in
                ${profileCases}
                *)
                  printf 'unknown profile: %s\n' "''${2:-}" >&2
                  exit 2
                  ;;
              esac
              [ -n "$profile" ] || {
                printf 'unknown profile: %s\n' "''${2:-}" >&2
                exit 2
              }
              mkdir -p "$workspace/models" "$workspace/workflows" "$workspace/custom_nodes" \
                "$workspace/input" "$workspace/output" "$(dirname "$profileState")"
              download-comfyui-models --manifest "$manifest" --root "$workspace/models"
              cp -rn "$resources/workflows/." "$workspace/workflows/"
              cp -rn "$resources/input/." "$workspace/input/"
              cp -rn "$resources/custom_nodes/." "$workspace/custom_nodes/"
              touch "$profileState"
              printf 'installed %s\n' "$profile"
              ;;
            start)
              if [ -z "''${2:-}" ]; then
                for candidate in ${profileNames}; do
                  if [ -f "$workspace/.nix-comfy/$candidate" ]; then
                    set -- start "$candidate"
                    break
                  fi
                done
              fi
              case ''${2:-} in
                ${profileCases}
                *)
                  printf 'usage: nix-comfy start <profile> [comfyui arguments...]\n' >&2
                  exit 2
                  ;;
              esac
              [ -f "$profileState" ] || {
                printf 'profile %s is not installed; run nix-comfy install %s\n' "$profile" "$profile" >&2
                exit 1
              }
              ${runtimeEnvironment}
              exec comfyui \
                --listen "''${COMFYUI_LISTEN:-$profileListen}" \
                --port "''${COMFYUI_PORT:-$profilePort}" \
                --base-directory "$workspace" \
                ${runtimeArgs} \
                "''${@:3}"
              ;;
            status)
              for profile in ${
                pkgs.lib.escapeShellArg
                (map (profile: profile.profileName) profilePackages)
              }; do
                if [ -f "$workspace/.nix-comfy/$profile" ]; then
                  printf '%s: installed\n' "$profile"
                else
                  printf '%s: not installed\n' "$profile"
                fi
              done
              ;;
            *)
              printf 'usage: nix-comfy {profiles|install <profile>|start <profile>|status}\n' >&2
              exit 2
              ;;
          esac
        '';
      };
      pinnedFlake = pkgs.linkFarm "comfyui-nix-flake-pinned" [
        {
          name = "opt/comfyui-nix-flake";
          path = ../.;
        }
        {
          name = "opt/nixpkgs";
          path = inputs.nixpkgs;
        }
      ];
      entrypoint = pkgs.writeShellApplication {
        name = "comfyui-entrypoint";
        runtimeInputs =
          [ pkgs.bash pkgs.coreutils pkgs.comfyui downloadModels nixComfy ];
        text = ''
          set -euo pipefail

          workspace="''${COMFYUI_WORKSPACE:-/workspace}"
          mkdir -p "$workspace/models" "$workspace/workflows" "$workspace/custom_nodes" "$workspace/input" "$workspace/output"

          ${runtimeEnvironment}

          exec nix-comfy start "$@"
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
          pkgs.nix
          pkgs.git
          pinnedFlake
          downloadModels
          nixComfy
          entrypoint
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
    in {
      packages.default = pkgs.comfyui;
      packages.comfyui = pkgs.comfyui;
      packages.models = pkgs.writeText "models.json" manifest;
      packages.workflows = workflows;
      packages.input-assets = inputAssets;
      packages.custom-nodes = customNodes;
      packages.container = image;
      packages.nix-comfy = nixComfy;

      apps.default = {
        type = "app";
        program = "${entrypoint}/bin/comfyui-entrypoint";
      };

      formatter = pkgs.nixfmt-rfc-style;
    };
}
