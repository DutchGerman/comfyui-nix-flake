{ pkgs }:
let
  qwenImage = import ./qwen-image-2-1.nix { inherit pkgs; };
  selectedProfiles = [ qwenImage ];

  runtimeValue = profiles: key: default:
    let
      values = builtins.filter (
        profile: builtins.hasAttr key (profile.runtime or { })
      ) (map (profile: profile) profiles);
      selectedValues = map (profile: (profile.runtime or { }).${key}) values;
    in
    if selectedValues == [ ] then
      default
    else
      builtins.head selectedValues;

  compose = profiles:
    let
      models = builtins.concatLists (map (profile: profile.models or [ ]) profiles);
      workflows = builtins.concatLists (map (profile: profile.workflows or [ ]) profiles);
      inputAssets = builtins.concatLists (map (profile: profile.inputAssets or [ ]) profiles);
      customNodes = builtins.concatLists (map (profile: profile.customNodes or [ ]) profiles);
      runtime = {
        listen = runtimeValue profiles "listen" "0.0.0.0";
        port = runtimeValue profiles "port" 8188;
        extraArgs = runtimeValue profiles "extraArgs" [ ];
        environment = runtimeValue profiles "environment" { };
      };
    in
    {
      inherit models workflows inputAssets customNodes runtime;
    };
in
{
  inherit qwenImage;

  selected = selectedProfiles;

  inherit compose;
}
