{ inputs, ... }: {
  perSystem = { pkgs, ... }:
    let
      profiles = import ../profiles { inherit pkgs; };
      profilePackage = profile:
        let
          composed = profiles.compose [ profile ];
          name = profile.installName or profile.name;
          json = builtins.toJSON {
            inherit name;
            installName = name;
            inherit (composed) models runtime dependencies;
          };
          farm = label: entries:
            pkgs.linkFarm label (map (entry: {
              inherit (entry) name;
              path = entry.source;
            }) entries);
        in pkgs.linkFarm "nix-comfy-profile-${name}" [
          {
            name = "profile.json";
            path = pkgs.writeText "${name}-profile.json" json;
          }
          {
            name = "models.json";
            path = pkgs.writeText "${name}-models.json"
              (builtins.toJSON composed.models);
          }
          {
            name = "workflows";
            path = farm "${name}-workflows" composed.workflows;
          }
          {
            name = "input";
            path = farm "${name}-input" composed.inputAssets;
          }
          {
            name = "custom_nodes";
            path = farm "${name}-custom-nodes" composed.customNodes;
          }
        ];
      profileEntries = map (profile: {
        name = profile.installName or profile.name;
        output = "profile-${profile.installName or profile.name}";
        package = profilePackage profile;
      }) profiles.available;
      profileIndex = pkgs.writeText "profile-index.json" (builtins.toJSON
        (map ({ name, output, ... }: { inherit name output; }) profileEntries));
      profileAttrs = builtins.listToAttrs (map (entry: {
        name = entry.output;
        value = entry.package;
      }) profileEntries);
      downloader = pkgs.writeShellApplication {
        name = "download-comfyui-models";
        runtimeInputs = [ pkgs.python3 ];
        text = ''exec python3 ${../runtime/download-models.py} "$@"'';
      };
      profileList = pkgs.writeShellApplication {
        name = "nix-comfy";
        runtimeInputs = [
          pkgs.bash
          pkgs.coreutils
          pkgs.cacert
          pkgs.git
          pkgs.nix
          pkgs.python3
          pkgs.comfyui
          downloader
        ];
        text = ''
                    set -euo pipefail
                    workspace="''${COMFYUI_WORKSPACE:-/workspace}"
                    remote="''${NIX_COMFY_FLAKE:-github:DutchGerman/comfyui-nix-flake/master}"
                    state="$workspace/.nix-comfy"
                    mkdir -p "$state" "$workspace"
                    # Runpod images do not have a Nix daemon. Use a local root store and
                    # append these settings so an inherited value cannot override them.
                    export NIX_REMOTE=local
                    export NIX_CONFIG="''${NIX_CONFIG:-}
                    experimental-features = nix-command flakes
                    sandbox = false
                    build-users-group ="
                    if ! nix-store --init 2>/dev/null; then
                      printf 'Nix local store is unavailable; provide a writable /nix store (or NIX_CONFIG store) before installing profiles\n' >&2
                      exit 1
                    fi

                    index_file="$state/profile-index.json"
                    locked_remote="$state/locked-flake"
                    locked_revision="$state/locked-revision"
                    resolve_index() {
                      metadata=$(nix flake metadata "$remote" --json)
                      printf '%s' "$metadata" > "$state/flake-metadata.json"
                      python3 - "$state/flake-metadata.json" "$locked_remote" "$locked_revision" <<'PY'
                    import json, pathlib, sys

                    metadata = json.load(open(sys.argv[1]))["locked"]
                    if metadata["type"] != "github":
                        raise SystemExit("NIX_COMFY_FLAKE must resolve to a GitHub flake")
                    pathlib.Path(sys.argv[2]).write_text(
                        f"github:{metadata['owner']}/{metadata['repo']}/{metadata['rev']}\n"
                    )
                    pathlib.Path(sys.argv[3]).write_text(metadata["rev"] + "\n")
                    PY
                      locked=$(<"$locked_remote")
                      nix build "$locked#profile-index" --no-link --print-out-paths > "$state/index-path"
                      index_path=$(<"$state/index-path")
                      cp "$index_path" "$index_file"
                    }
                    profile_output() {
                      python3 - "$index_file" "$1" <<'PY'
          import json, sys
          for item in json.load(open(sys.argv[1])):
              if item["name"] == sys.argv[2]:
                  print(item["output"])
                  break
          else:
              raise SystemExit(1)
          PY
                    }
                    case ''${1:-} in
                      profiles)
                        resolve_index
                        python3 - "$index_file" <<'PY'
          import json, sys
          for item in json.load(open(sys.argv[1])): print(item["name"])
          PY
                        ;;
                      install)
                        [ -n "''${2:-}" ] || { printf 'usage: nix-comfy install <profile>\n' >&2; exit 2; }
                        case "$2" in
                          *[!A-Za-z0-9._-]*)
                            printf 'invalid profile name: %s\n' "$2" >&2
                            exit 2
                            ;;
                        esac
                        resolve_index
                        output=$(profile_output "$2") || { printf 'unknown profile: %s\n' "$2" >&2; exit 2; }
                        locked=$(<"$locked_remote")
                        revision=$(<"$locked_revision")
                        built=$(nix build "$locked#$output" --no-link --print-out-paths)
                        profiles_root="$workspace/profiles"
                        mkdir -p "$profiles_root"
              temporary=$(mktemp -d "$profiles_root/.$2.XXXXXX")
              trap 'rm -rf "$temporary"' EXIT
                        root="$temporary"
                        mkdir -p "$root/models" "$root/workflows" "$root/custom_nodes" "$root/input" "$root/output"
                        cp "$built/profile.json" "$root/profile.json"
                        download=$(command -v download-comfyui-models || true)
                        [ -n "$download" ] || { printf 'model downloader is missing from the image\n' >&2; exit 1; }
              "$download" --manifest "$built/models.json" --root "$root/models"
                        cp -rL "$built/workflows/." "$root/workflows/"
                        cp -rL "$built/input/." "$root/input/"
              cp -rL "$built/custom_nodes/." "$root/custom_nodes/"
              printf '%s\n' "$revision" > "$root/.revision"
              touch "$root/.complete"
              current="$profiles_root/$2"
              if [ -d "$current" ] && [ ! -L "$current" ]; then
                mv "$current" "$profiles_root/.$2.legacy.$RANDOM"
              fi
              rm -f "$profiles_root/.$2.next"
              ln -s "$(basename "$temporary")" "$profiles_root/.$2.next"
              mv -Tf "$profiles_root/.$2.next" "$current"
              trap - EXIT
                        printf 'installed %s at %s\n' "$2" "$revision"
                        ;;
            start)
              profile="''${2:-}"
              case "$profile" in
                ""|*[!A-Za-z0-9._-]*)
                  if [ -n "$profile" ]; then
                    printf 'invalid profile name: %s\n' "$profile" >&2
                    exit 2
                  fi
                  ;;
              esac
              if [ -z "$profile" ]; then
                profiles=$(find "$workspace/profiles" -mindepth 1 -maxdepth 1 -type l 2>/dev/null || true)
                          count=$(printf '%s\n' "$profiles" | sed '/^$/d' | wc -l)
                          [ "$count" -eq 1 ] || { printf 'specify a profile; installed profiles: %s\n' "''${profiles:-none}" >&2; exit 2; }
                          profile=$(basename "$profiles")
                        fi
                        root="$workspace/profiles/$profile"
                        [ -f "$root/.complete" ] || { printf 'profile %s is not installed; run nix-comfy install %s\n' "$profile" "$profile" >&2; exit 1; }
                        listen=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["runtime"].get("listen", "0.0.0.0"))' "$root/profile.json")
                        port=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["runtime"].get("port", 8188))' "$root/profile.json")
                        eval "$(python3 - "$root/profile.json" <<'PY'
          import json, shlex, sys
          p = json.load(open(sys.argv[1]))
          for key, value in p["runtime"].get("environment", {}).items():
              print("export %s=%s" % (key, shlex.quote(value)))
          PY
                        )"
                        readarray -t extra_args < <(python3 -c 'import json,sys; print("\n".join(json.load(open(sys.argv[1]))["runtime"].get("extraArgs", [])))' "$root/profile.json")
                        exec comfyui --listen "''${COMFYUI_LISTEN:-$listen}" --port "''${COMFYUI_PORT:-$port}" --base-directory "$root" "''${extra_args[@]}" "''${@:3}"
                        ;;
                      status)
                        for root in "$workspace"/profiles/*; do
                          [ -f "$root/.complete" ] || continue
                          printf '%s: %s\n' "$(basename "$root")" "$(cat "$root/.revision" 2>/dev/null || printf 'unknown')"
                        done
                        ;;
                      *) printf 'usage: nix-comfy {profiles|install <profile>|start [profile]|status}\n' >&2; exit 2 ;;
                    esac
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
          downloader
          profileList
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
      packages = profileAttrs // {
        default = pkgs.comfyui;
        comfyui = pkgs.comfyui;
        profile-index = profileIndex;
        container = image;
        nix-comfy = profileList;
        models = pkgs.writeText "models.json"
          (builtins.toJSON (profiles.compose profiles.selected).models);
      };
      formatter = pkgs.nixfmt-rfc-style;
    };
}
