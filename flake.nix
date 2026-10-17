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
            config = { allowUnfree = true; };
          };
          cuda = import ./lib/cuda-python.nix { inherit basePkgs; };
        in {
          _module.args.pkgs = cuda.pkgs;
          packages = cuda.packages;
          checks = cuda.checks;
        };
    };
}
