{ pkgs }:
let
  qwenImage = import ./qwen-image-2-1.nix { inherit pkgs; };
  mossImage = import ./moss-image.nix { inherit pkgs; };
  availableProfiles = [ qwenImage mossImage ];
  selectedProfiles = availableProfiles;

  resourceNames = resources: map (resource: resource.name) resources;
  unique = label: names:
    builtins.foldl' (seen: name:
      if builtins.elem name seen then
        throw "duplicate ${label} destination: ${name}"
      else
        seen ++ [ name ]) [ ] names;

  runtimeValue = profiles: key: default:
    let
      values =
        builtins.filter (profile: builtins.hasAttr key (profile.runtime or { }))
        (map (profile: profile) profiles);
      selectedValues = map (profile: (profile.runtime or { }).${key}) values;
    in if selectedValues == [ ] then
      default
    else if builtins.all (value:
      builtins.toJSON value == builtins.toJSON (builtins.head selectedValues))
    selectedValues then
      builtins.head selectedValues
    else
      throw "conflicting runtime setting: ${key}";

  validModel = model:
    model ? provider
    && builtins.elem model.provider [ "huggingface" "civitai" "url" ] && model
    ? name && model.name != "" && model ? directory && model.directory != ""
    && model ? url && model.url != "" && model ? sha256
    && builtins.stringLength model.sha256 == 64
    && builtins.match "[0-9a-fA-F]*" model.sha256 != null;

  compose = profiles:
    let
      models =
        builtins.concatLists (map (profile: profile.models or [ ]) profiles);
      workflows =
        builtins.concatLists (map (profile: profile.workflows or [ ]) profiles);
      inputAssets = builtins.concatLists
        (map (profile: profile.inputAssets or [ ]) profiles);
      customNodes = builtins.concatLists
        (map (profile: profile.customNodes or [ ]) profiles);
      modelDestinations =
        map (model: "${model.directory}/${model.name}") models;
      runtime = {
        listen = runtimeValue profiles "listen" "0.0.0.0";
        port = runtimeValue profiles "port" 8188;
        extraArgs = runtimeValue profiles "extraArgs" [ ];
        environment = runtimeValue profiles "environment" { };
      };
      dependencies = builtins.foldl'
        (result: profile: result // (profile.dependencies or { })) {
          python = [ ];
          customNodes = [ ];
        } profiles;
    in assert builtins.all validModel models;
    assert unique "model" modelDestinations == modelDestinations;
    assert unique "workflow" (resourceNames workflows)
      == resourceNames workflows;
    assert unique "input asset" (resourceNames inputAssets)
      == resourceNames inputAssets;
    assert unique "custom node" (resourceNames customNodes)
      == resourceNames customNodes; {
        inherit models workflows inputAssets customNodes runtime dependencies;
      };
in {
  inherit qwenImage;
  inherit mossImage;

  available = assert unique "profile"
    (map (profile: profile.installName or profile.name) availableProfiles)
    == map (profile: profile.installName or profile.name) availableProfiles;
    availableProfiles;

  selected = selectedProfiles;

  inherit compose;
}
