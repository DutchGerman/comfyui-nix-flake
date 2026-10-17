# comfyui-nix-flake

Modular Nix packaging for ComfyUI deployments.

This repository is a framework for composing ComfyUI installations from modules. A module can provide model downloads, workflows, custom nodes, and runtime configuration. Model weights are downloaded during profile installation into persistent storage and are not stored in Git or the Nix store.

## Quick Start

Inspect the available outputs:

```sh
nix flake show
```

Build the Runpod image:

```sh
nix build .#container
```

The result is an OCI image archive. Import it with Docker or Podman and run it with an NVIDIA GPU and a persistent volume mounted at `/workspace`.

The published image is `ghcr.io/dutchgerman/comfyui-nix-flake:latest` (the commit SHA is also published as a tag). It includes Nix, Git, CUDA-enabled ComfyUI using nixpkgs' prebuilt CUDA PyTorch wheels, the checksum downloader, and a generic runtime CLI, but no repository profiles or model weights. The single-GPU runtime does not build or enable NCCL distributed support. The default container command keeps the pod alive for SSH access:

```sh
docker run --gpus all -p 8188:8188 -v comfyui-workspace:/workspace \
  ghcr.io/dutchgerman/comfyui-nix-flake:latest
```

From the pod, install the profile once and start ComfyUI in the foreground:

```sh
nix-comfy profiles
nix-comfy install qwen-image-2-1-t2i
nix-comfy status
nix-comfy start qwen-image-2-1-t2i
```

`nix-comfy` resolves the latest `github:DutchGerman/comfyui-nix-flake/master` profile index, builds that profile output with Nix, records its locked Git revision, and installs it below `/workspace/profiles/<profile>`. Thus adding or changing a profile does not rebuild the base OCI image. `profiles` always queries the remote index; use a profile revision shown by `status` when auditing an installation.

The container workflow ignores profile-only changes. `.github/workflows/profiles.yml` evaluates and builds profile outputs instead. After the first publish, set the GHCR package visibility to **Public** in the package settings so Runpod can pull it without registry credentials.

### Runpod Pod

Create a CUDA-enabled GPU Pod using the published image. Configure:

- Container image: `ghcr.io/dutchgerman/comfyui-nix-flake:latest`
- Persistent volume mounted at `/workspace`
- 30 GB container disk
- 100 GB persistent volume mounted at `/workspace`
- HTTP port `8188`
- Optional runtime secret: `HF_TOKEN`

After connecting to the Pod terminal over SSH:

```sh
nix-comfy profiles
nix-comfy install qwen-image-2-1-t2i
nix-comfy status
nix-comfy start qwen-image-2-1-t2i
```

Keep the Pod running while ComfyUI is in use. Open the Runpod HTTP service for port `8188`; the workflow is installed at `/workspace/profiles/qwen-image-2-1-t2i/workflows/qwen-image-2-1-t2i.json` and generated images are written to that profile's `output` directory.

## Modules

The reference module is `profiles/qwen-image-2-1.nix`. It declares models and workflows without embedding model files in the repository.

New modules should follow the same shape:

```nix
{ pkgs }:
{
  name = "my-module";
  models = [
    {
      provider = "huggingface";
      name = "model.safetensors";
      directory = "checkpoints";
      url = "https://example.invalid/model.safetensors";
      sha256 = "...";
      required = true;
    }
  ];
  workflows = [
    {
      name = "my-workflow.json";
      source = pkgs.fetchurl { url = "..."; hash = "..."; };
    }
  ];
  inputAssets = [
    {
      name = "reference.png";
      source = ./assets/reference.png;
    }
  ];
  customNodes = [
    {
      name = "example-node";
      source = pkgs.fetchgit {
        url = "https://github.com/example/custom-node.git";
        rev = "...";
        hash = "sha256-...";
      };
    }
  ];
  runtime = {
    port = 8188;
    extraArgs = [ ];
    environment = { };
  };
}
```

Model entries must declare `provider` as `huggingface`, `civitai`, or `url`. Hugging Face uses `HF_TOKEN`, CivitAI uses `CIVITAI_TOKEN`, and direct URLs may set `authEnv` for generic Bearer authentication. Every model requires a 64-character SHA-256 checksum. Required download failures stop installation; optional failures are logged and skipped.

Input assets are immutable Nix inputs copied into the installed profile. Workflows and custom nodes are pinned into the profile output/store and copied into persistent profile storage. Duplicate resource names and conflicting runtime settings fail during Nix evaluation rather than being overwritten.

Each profile is exposed as `.#profile-<installName>` and `.#profile-index`. A profile output contains `profile.json`, `models.json`, workflows, input assets, and custom nodes; model weights are downloaded only during `install`. Add a profile to `profiles/default.nix` and `available` and set `installName` to define its CLI name. Dependency metadata (`dependencies.python` and `dependencies.customNodes`) is recorded, but arbitrary custom-node Python dependencies are not installed by this MVP.

## Credentials

Set credentials only at runtime. Supported model manifests can reference an environment variable such as `HF_TOKEN` or `CIVITAI_TOKEN`. Never put a token in a Nix expression, workflow, image, or Git repository.

## Storage

Mount persistent storage at `/workspace`. Profiles are isolated under:

- `/workspace/profiles/<profile>/models`
- `/workspace/profiles/<profile>/workflows`
- `/workspace/profiles/<profile>/custom_nodes`
- `/workspace/profiles/<profile>/input`
- `/workspace/profiles/<profile>/output`

The container accepts `HF_TOKEN`, `CIVITAI_TOKEN`, `COMFYUI_WORKSPACE`, `COMFYUI_LISTEN`, and `COMFYUI_PORT` at runtime. It targets a persistent Runpod Pod with HTTP port `8188`; Serverless handlers and application-level authentication are out of scope.

The Qwen Image 2.1 example needs substantial model storage. Plan for the 100 GB persistent volume; the 30 GB container disk must also retain the Nix store created by runtime profile builds.

The image runs Nix as a root-capable single-user local-store setup: `nix-comfy` sets `sandbox = false` and an empty build-users group because Runpod does not provide NixOS/systemd or a daemon. The image's writable `/nix` layer is required for `nix build`; mount or persist it if the platform resets the container layer. This is deliberately explicit rather than pretending a daemon-backed store is available.

The MVP tracks revisions at install time but follows the moving `master` ref for the next install. There is no separate `update` command; reinstalling refreshes a profile. `start` with no profile is allowed only when exactly one profile is installed.

## Licensing

Repository-owned source code is GPL-3.0-only. Models and custom nodes retain their own licenses. Qwen Image 2.1 uses the Qwen Research License and is intended here for personal, non-commercial use. Review every model and custom-node license before deploying a module.

## Development Environment

This repository includes a sandboxed OpenCode setup with Nix-focused agents. Restart OpenCode after changing `.opencode/` configuration files.
