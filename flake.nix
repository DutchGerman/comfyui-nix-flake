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
            };
          };
          pythonPackages = basePkgs.python313Packages;
          torch = pythonPackages.buildPythonPackage {
            pname = "torch";
            version = "2.12.1+cu130";
            format = "wheel";
            src = basePkgs.fetchurl {
              url = "https://download-r2.pytorch.org/whl/cu130/torch-2.12.1%2Bcu130-cp313-cp313-manylinux_2_28_x86_64.whl";
              hash = "sha256-1eGEBELSGClXs9L3eMwyXJD6XLQqqLGslJ8CnpvdfwY=";
            };
            dependencies = with pythonPackages; [
              filelock
              fsspec
              jinja2
              networkx
              sympy
              typing-extensions
            ];
            passthru.cudaSupport = true;
            pythonImportsCheck = [ "torch" ];
          };
          torchvision = pythonPackages.buildPythonPackage {
            pname = "torchvision";
            version = "0.27.1+cu130";
            format = "wheel";
            src = basePkgs.fetchurl {
              url = "https://download-r2.pytorch.org/whl/cu130/torchvision-0.27.1%2Bcu130-cp313-cp313-manylinux_2_28_x86_64.whl";
              hash = "sha256-+fAI1LGy8BPq977Bqf8iEmNYHXdmjU4eDpw+01HVZGU=";
            };
            dependencies = with pythonPackages; [
              numpy
              pillow
              torch
            ];
            passthru.cudaSupport = true;
            pythonImportsCheck = [ "torchvision" ];
          };
          cudaPython = basePkgs.python313.override {
            packageOverrides = final: prev: {
              inherit torch torchvision;
            };
          };
          pkgs = basePkgs // {
            python3 = cudaPython;
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
