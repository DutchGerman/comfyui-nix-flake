{ pkgs }: {
  name = "moss-image";
  installName = "moss-image";

  models = [
    {
      provider = "huggingface";
      name = "moss_image_base_int8_convrot.safetensors";
      directory = "diffusion_models";
      url =
        "https://huggingface.co/DutchGerman/comfyui-nix-flake/resolve/main/moss_image_base_int8_convrot.safetensors";
      sha256 =
        "f601c1e1161915fb3fea003da0c1782e374dd960fbb3978bc0e4e3fa1f2d8e6f";
      required = true;
    }
    {
      provider = "huggingface";
      name = "Qwen3.5-9B-abliterated_int8_convrot.safetensors";
      directory = "text_encoders";
      url =
        "https://huggingface.co/DutchGerman/comfyui-nix-flake/resolve/main/Qwen3.5-9B-abliterated_int8_convrot.safetensors";
      sha256 =
        "e7ba909fd9d9e2557eb566e00ffb34226706f3e7425dc3f187246382edc282f6";
      required = true;
    }
    {
      provider = "huggingface";
      name = "flux2-vae_small.safetensors";
      directory = "vae";
      url =
        "https://huggingface.co/DutchGerman/comfyui-nix-flake/resolve/main/flux2-vae_small.safetensors";
      sha256 =
        "d8d52ba036475f5fb07c8b435e176d3d97ebfa82f0d1a1c317f9cc1e25bd013b";
      required = true;
    }
    {
      provider = "huggingface";
      name = "8-steps-dmd2-lora.safetensors";
      directory = "loras";
      url =
        "https://huggingface.co/DutchGerman/comfyui-nix-flake/resolve/main/8-steps-dmd2-lora.safetensors";
      sha256 =
        "7683fe1fb51f73f5d690f24dd6b7f46f31ab9a9873729a854ac5c9a420ffe6f2";
      required = true;
    }
    {
      provider = "huggingface";
      name = "moss_image_sft.safetensors";
      directory = "loras";
      url =
        "https://huggingface.co/DutchGerman/comfyui-nix-flake/resolve/main/moss_image_sft.safetensors";
      sha256 =
        "6b443a4597694769b527a43d5aed7f0c8265d59a9eceab164ab29eb4bb3af7bf";
      required = true;
    }
    {
      provider = "huggingface";
      name = "moss-control.safetensors";
      directory = "loras";
      url =
        "https://huggingface.co/DutchGerman/comfyui-nix-flake/resolve/main/moss-control.safetensors";
      sha256 =
        "e5c0c3efd05e4269207a39de6005798f14c90c6687c89c54eaffe4b76c43a763";
      required = true;
    }
  ];

  workflows = [ ];
  customNodes = [
    {
      name = "ComfyUI-Manager";
      source = pkgs.fetchgit {
        url = "https://github.com/ltdrdata/ComfyUI-Manager.git";
        rev = "7e1af9c202fbd0051df3da43572976acd12857dc";
        hash = "sha256-DVr+DlvCaihHv5nU6b879zse/PyGFEt+9LfbRQxCYpA=";
      };
    }
    {
      name = "rgthree-comfy";
      source = pkgs.fetchgit {
        url = "https://github.com/rgthree/rgthree-comfy.git";
        rev = "d7297b42f0fa78bec1c0411478f887423c249502";
        hash = "sha256-MBH4fgZBQKcKJ353AusNIOYadGom4nbyTFVGQEJbyFQ=";
      };
    }
    {
      name = "ComfyUI-KJNodes";
      source = pkgs.fetchgit {
        url = "https://github.com/kijai/ComfyUI-KJNodes.git";
        rev = "2371136d2fa6fd0914e514cd99b36dabe5db9adf";
        hash = "sha256-1qJrNm+YnjVFP05DZzKFHS2UYx5qK0aEWPP0NlHJ4EM=";
      };
    }
    {
      name = "comfyui_controlnet_aux";
      source = pkgs.fetchgit {
        url = "https://github.com/Fannovel16/comfyui_controlnet_aux.git";
        rev = "a587a4c1594524c1d2de5cd1a86cd868ff448e1c";
        hash = "sha256-sIagHbtP1W+bF63AlaqZZ/Gtc0yqc67ur64h8BWxdc4=";
      };
    }
    {
      name = "RES4LYF";
      source = pkgs.fetchgit {
        url = "https://github.com/ClownsharkBatwing/RES4LYF.git";
        rev = "56e44755d866c87ff9cb4b6608c8e42155db6ecc";
        hash = "sha256-zuj8R0JOJjNpPOFozwWD1Odi/q+avWcQF766iifXe2M=";
      };
    }
  ];
  inputAssets = [ ];

  dependencies = {
    python = [ ];
    customNodes = [ ];
  };
}
