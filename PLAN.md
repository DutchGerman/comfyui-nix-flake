# comfyui-nix-flake Plan

## Goal

Build a modular Nix-based ComfyUI deployment framework for NVIDIA CUDA and Runpod.

The repository lets users define modules containing models, workflows, custom nodes, and runtime configuration. Qwen Image 2.1 is the first example module.

## Scope

- Public repository with GPL-3.0-only source code
- NVIDIA CUDA on x86_64-linux
- Runpod-compatible OCI image
- Persistent `/workspace` storage
- Runtime model downloads
- Hugging Face, CivitAI, and direct URL sources
- Declaratively pinned custom nodes
- Sandboxed OpenCode, Codex, and Claude development tools
- No `agent-check` in the MVP

## Module System

Modules declare models, destination directories, URLs, checksums, credentials, workflows, input assets, custom nodes, revisions, and runtime configuration. Module composition produces one ComfyUI deployment.

## First Example

The Qwen Image 2.1 module provides the official text-to-image workflow and its INT8 diffusion model, text encoder, VAE, and optional prompt enhancer. Model files remain outside Git and download to persistent storage at startup.

## Implementation Phases

1. Create the flake-parts repository structure.
2. Add the OpenCode sandbox and repository instructions.
3. Use the nixpkgs ComfyUI package as the initial runtime.
4. Define the model, workflow, and custom-node module interface.
5. Implement checksum-verified runtime model downloads.
6. Add the Qwen Image 2.1 example module.
7. Add the Runpod OCI image.
8. Validate flake outputs and startup configuration.
9. Document how users create and compose modules.

## Acceptance Criteria

- Users can select one or more modules declaratively.
- ComfyUI starts on NVIDIA CUDA and listens on port 8188.
- Required models download to persistent storage and verified files are reused.
- The Qwen workflow is available in ComfyUI.
- No model weights or secrets are committed.
- Custom nodes can be pinned reproducibly.
- The OCI image can be used by a Runpod Pod.
- The README explains how to create a module.
