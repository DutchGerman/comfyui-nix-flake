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
      name = "model.safetensors";
      directory = "checkpoints";
      url = "https://example.invalid/model.safetensors";
      sha256 = "...";
      authEnv = "HF_TOKEN";
      required = true;
    }
  ];
  workflows = [
    {
      name = "my-workflow.json";
      source = pkgs.fetchurl { url = "..."; hash = "..."; };
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
}
```

The current MVP composes the reference module into the default image. Add another profile to `profiles/default.nix` and include it in `selected` to compose additional modules.

## Credentials

Set credentials only at runtime. Supported model manifests can reference an environment variable such as `HF_TOKEN` or `CIVITAI_TOKEN`. Never put a token in a Nix expression, workflow, image, or Git repository.

## Storage

Mount persistent storage at `/workspace`. The entrypoint creates:

- `/workspace/models`
- `/workspace/workflows`
- `/workspace/custom_nodes`
- `/workspace/input`
- `/workspace/output`

The Qwen Image 2.1 example needs substantial model storage. Plan for at least 50 GB for the initial profile and container overhead.

## Licensing

Repository-owned source code is GPL-3.0-only. Models and custom nodes retain their own licenses. Qwen Image 2.1 uses the Qwen Research License and is intended here for personal, non-commercial use. Review every model and custom-node license before deploying a module.

## Development Environment

This repository includes a sandboxed OpenCode setup with Nix-focused agents. Restart OpenCode after changing `.opencode/` configuration files.
