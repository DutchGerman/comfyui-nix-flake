{ inputs, ... }:
{
  perSystem = { pkgs, ... }:
    let
      profiles = import ../profiles { inherit pkgs; };
      profileModule = import ./profiles.nix {
        inherit pkgs profiles;
      };
      runtimeModule = import ./runtime.nix {
        inherit pkgs;
      };
      containerModule = import ./container.nix {
        inherit pkgs runtimeModule;
      };
    in
    {
      packages = profileModule.packages
        // runtimeModule.packages
        // containerModule.packages
        // {
          default = pkgs.comfyui;
          comfyui = pkgs.comfyui;
        };
      formatter = pkgs.nixfmt-rfc-style;
    };
}
