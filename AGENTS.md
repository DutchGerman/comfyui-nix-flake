# comfyui-nix-flake

## Project identity

This repository contains a modular Nix framework for ComfyUI deployments.

## General instructions

- Make the smallest reasonable change.
- Use existing module and manifest patterns before adding abstractions.
- Use the `yagni` skill before adding dependencies, helpers, or configuration.
- Keep model weights and credentials out of Git and the Nix store.
- Keep model and custom-node licenses separate from the repository license.
- Prefer focused `nix eval` and `nix build` checks.
- Do not run `nix develop` automatically.

## Module rules

- Modules declare models, workflows, and custom nodes.
- Every downloaded model must have a checksum.
- Required and optional downloads must be explicit.
- Custom nodes must be pinned to a revision or release.
- Runtime state belongs under persistent `/workspace`.

## OpenCode

Use the repository-local OpenCode agents and skills. The sandbox is for development tooling; the ComfyUI container is a separate runtime artifact.
