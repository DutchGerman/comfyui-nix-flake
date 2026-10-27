{ pkgs, profiles }:
let
  profilePackage = profile:
    let
      composed = profiles.compose [ profile ];
      name = profile.installName or profile.name;
      json = builtins.toJSON {
        inherit name;
        installName = name;
        comfyuiMain = "${pkgs.comfyuiSource}/main.py";
        inherit (composed) models runtime dependencies;
      };
      farm = label: entries:
        pkgs.linkFarm label (map (entry: {
          inherit (entry) name;
          path = entry.source;
        }) entries);
    in
    pkgs.linkFarm "nix-comfy-profile-${name}" [
      {
        name = "profile.json";
        path = pkgs.writeText "${name}-profile.json" json;
      }
      {
        name = "models.json";
        path = pkgs.writeText "${name}-models.json"
          (builtins.toJSON composed.models);
      }
      {
        name = "workflows";
        path = farm "${name}-workflows" composed.workflows;
      }
      {
        name = "input";
        path = farm "${name}-input" composed.inputAssets;
      }
      {
        name = "custom_nodes";
        path = farm "${name}-custom-nodes" composed.customNodes;
      }
    ];

  profileEntries = map (profile: {
    name = profile.installName or profile.name;
    output = "profile-${profile.installName or profile.name}";
    package = profilePackage profile;
  }) profiles.available;
  profileIndex = pkgs.writeText "profile-index.json" (builtins.toJSON
    (map ({ name, output, ... }: { inherit name output; }) profileEntries));
  profileAttrs = builtins.listToAttrs (map (entry: {
    name = entry.output;
    value = entry.package;
  }) profileEntries);
in
{
  packages = profileAttrs // {
    profile-index = profileIndex;
    models = pkgs.writeText "models.json"
      (builtins.toJSON (profiles.compose profiles.selected).models);
  };
}
