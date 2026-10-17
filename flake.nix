{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    jail-nix.url = "sourcehut:~alexdavid/jail.nix";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ ./modules ./tools/agents ];

      perSystem = { system, ... }:
        let
          basePkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              cudaSupport = true;
            };
          };
          cudaPython = basePkgs.python3.override {
            packageOverrides = final: prev: {
              # Use nixpkgs' CUDA wheels instead of compiling PyTorch and NCCL.
              torch = prev."torch-bin";
              torchvision = prev."torchvision-bin";
            };
          };
          pkgs = basePkgs // {
            comfyui = basePkgs.comfyui.override { python3 = cudaPython; };
          };
        in {
          _module.args.pkgs = pkgs;
          checks.cuda-enabled = pkgs.runCommand "comfyui-cuda-enabled" { } ''
            test "${
              if pkgs.comfyui.python.pkgs.torch.cudaSupport then
                "true"
              else
                "false"
            }" = true
            touch "$out"
          '';
        };
    };
}
