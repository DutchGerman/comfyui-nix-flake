{ pkgs }:
let
  qwenImage = import ./qwen-image-2-1.nix { inherit pkgs; };
in
{
  inherit qwenImage;

  selected = [ qwenImage ];

  compose = profiles: {
    models = builtins.concatLists (map (profile: profile.models) profiles);
    workflows = builtins.concatLists (map (profile: profile.workflows) profiles);
    customNodes = builtins.concatLists (map (profile: profile.customNodes) profiles);
  };
}
