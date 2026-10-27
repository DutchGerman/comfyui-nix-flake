{ basePkgs, cudaPython, torch, torchvision }:
let
  pythonPackages = basePkgs.python313Packages;
  comfyuiFrontend = pythonPackages.buildPythonPackage {
    pname = "comfyui-frontend-package";
    version = "1.57.4";
    format = "wheel";
    src = basePkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/2c/f3/a7f851e2bfab98b312e54e9f3ea50e677b0e6f28deb06b0ac23e409546f3/comfyui_frontend_package-1.57.4-py3-none-any.whl";
      hash = "sha256-LERy1ZQ6wY+QmK81ZeMZxv/MHspdhz2l1ircQQ+PQ70=";
    };
    doCheck = false;
    pythonImportsCheck = [ "comfyui_frontend_package" ];
  };
  comfyuiEmbeddedDocs = pythonPackages.buildPythonPackage {
    pname = "comfyui-embedded-docs";
    version = "0.5.15";
    format = "wheel";
    src = basePkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/cd/9d/913821c24d46a7ba80eef9cd769a5a3e344101f80f38e4bc3551bb3ba22e/comfyui_embedded_docs-0.5.15-py3-none-any.whl";
      hash = "sha256-cWfhOw8yioAYTmnNcF6h/yi4AyBlUX5O+Ck7CNXlKO4=";
    };
    doCheck = false;
    pythonImportsCheck = [ "comfyui_embedded_docs" ];
  };
  comfyAimdo = pythonPackages.buildPythonPackage {
    pname = "comfy-aimdo";
    version = "0.6.0";
    format = "wheel";
    src = basePkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/21/7a/d349443e634d56ab3c1d5b279f0d4858e29905234de03171f840258e4a83/comfy_aimdo-0.6.0-cp39-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
      hash = "sha256-M2qWoKq+aQxZVYE6ejAT22cKWGkQreeYzaxLCGTrIqw=";
    };
    doCheck = false;
  };
  comfyKitchen = pythonPackages.buildPythonPackage {
    pname = "comfy-kitchen";
    version = "0.2.40";
    format = "wheel";
    src = basePkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/9c/2e/1c6c621a1cd2ba89ae12fe99e095faa50986c0e6485461170732adfcfa6d/comfy_kitchen-0.2.40-py3-none-any.whl";
      hash = "sha256-5YNPLOmTyNXqjAFlAVfGOXQrWijssNlSU3d/MbUkgJk=";
    };
    doCheck = false;
  };
  comfyuiWorkflowTemplates = pythonPackages.buildPythonPackage {
    pname = "comfyui-workflow-templates";
    version = "0.11.97";
    format = "wheel";
    src = basePkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/56/d8/56afa42460d83fe4d18c6cc9d9387b5bbe350065c916b565968475b95b9b/comfyui_workflow_templates-0.11.97-py3-none-any.whl";
      hash = "sha256-81KaSSVIYhuA7zbR4qfZgXpQZsvboowNK/w3hvY2vuU=";
    };
    dependencies = with pythonPackages; [
      comfyui-workflow-templates-core
      comfyui-workflow-templates-json
      comfyui-workflow-templates-media-api
      comfyui-workflow-templates-media-assets-01
      comfyui-workflow-templates-media-assets-02
      comfyui-workflow-templates-media-image
      comfyui-workflow-templates-media-other
      comfyui-workflow-templates-media-video
    ];
    pythonRelaxDeps = [
      "comfyui-workflow-templates-core"
      "comfyui-workflow-templates-json"
      "comfyui-workflow-templates-media-api"
      "comfyui-workflow-templates-media-assets-01"
      "comfyui-workflow-templates-media-assets-02"
      "comfyui-workflow-templates-media-image"
      "comfyui-workflow-templates-media-other"
      "comfyui-workflow-templates-media-video"
    ];
    doCheck = false;
    pythonImportsCheck = [ "comfyui_workflow_templates" ];
  };
  cpuPython = basePkgs.python313.override {
    packageOverrides = _: prev: {
      comfyui-frontend-package = comfyuiFrontend;
      comfyui-embedded-docs = comfyuiEmbeddedDocs;
      comfy-aimdo = comfyAimdo;
      comfy-kitchen = comfyKitchen;
      comfyui-workflow-templates = comfyuiWorkflowTemplates;
    };
  };
  comfyuiSource = basePkgs.fetchgit {
    url = "https://github.com/Comfy-Org/ComfyUI.git";
    rev = "426f5eea52a7ece1dd599fff4cb6cd1f352ddd24";
    hash = "sha256-3lv80HpyKFJHQTOaws1knIC7YdGkKm2S1WkVidUwMNI=";
  };
  comfyuiBase = basePkgs.comfyui.overrideAttrs (_: {
    version = "0.43.0";
    src = comfyuiSource;
  });
  comfyuiPython = cudaPython.override {
    packageOverrides = final: prev: {
      inherit torch torchvision;
      comfyui-frontend-package = comfyuiFrontend;
      comfyui-embedded-docs = comfyuiEmbeddedDocs;
      comfy-aimdo = comfyAimdo;
      comfy-kitchen = comfyKitchen;
      comfyui-workflow-templates = comfyuiWorkflowTemplates;
    };
  };
  pkgs = basePkgs // {
    python3 = comfyuiPython;
    comfyuiSource = comfyuiSource;
    comfyui = comfyuiBase.override { python3 = comfyuiPython; };
  };
in {
  inherit pkgs;
  packages = {
    comfyui-cpu = comfyuiBase.override { python3 = cpuPython; };
  };
}
