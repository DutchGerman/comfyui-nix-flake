# comfyui-nix-flake

Modular Nix packaging for ComfyUI deployments.

This repository is a framework for composing ComfyUI installations from modules. A module can provide model downloads, workflows, custom nodes, and runtime configuration. Model weights are downloaded at startup into persistent storage and are not stored in Git or the Nix store.

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

Model entries must declare `provider` as `huggingface`, `civitai`, or `url`. Hugging Face uses `HF_TOKEN`, CivitAI uses `CIVITAI_TOKEN`, and direct URLs may set `authEnv` for generic Bearer authentication. Every model requires a 64-character SHA-256 checksum. Required download failures stop startup; optional failures are logged and skipped.

Input assets are immutable Nix inputs copied to `/workspace/input`. Workflows and custom nodes are also pinned into the image/store. Duplicate resource names and conflicting runtime settings fail during Nix evaluation rather than being overwritten.

The current MVP composes the reference module into the default image. Add another profile to `profiles/default.nix` and include it in `selected` to compose additional modules. Runtime settings are limited to ComfyUI's listen address, port, extra CLI arguments, and environment variables.

## Credentials

Set credentials only at runtime. Supported model manifests can reference an environment variable such as `HF_TOKEN` or `CIVITAI_TOKEN`. Never put a token in a Nix expression, workflow, image, or Git repository.

## Storage

Mount persistent storage at `/workspace`. The entrypoint creates:

- `/workspace/models`
- `/workspace/workflows`
- `/workspace/custom_nodes`
- `/workspace/input`
- `/workspace/output`

The container accepts `HF_TOKEN`, `CIVITAI_TOKEN`, `COMFYUI_WORKSPACE`, `COMFYUI_LISTEN`, and `COMFYUI_PORT` at runtime. It targets a persistent Runpod Pod with HTTP port `8188`; Serverless handlers and application-level authentication are out of scope.

The Qwen Image 2.1 example needs substantial model storage. Plan for at least 50 GB for the initial profile and container overhead.

## Licensing

Repository-owned source code is GPL-3.0-only. Models and custom nodes retain their own licenses. Qwen Image 2.1 uses the Qwen Research License and is intended here for personal, non-commercial use. Review every model and custom-node license before deploying a module.

## Development Environment

This repository includes a sandboxed OpenCode setup with Nix-focused agents. Restart OpenCode after changing `.opencode/` configuration files.
