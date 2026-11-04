{ pkgs }: {
  name = "minimax-h3";
  installName = "minimax-h3";

  # The workflow is intentionally not bundled; import it directly in ComfyUI.
  models = [
    {
      provider = "huggingface";
      name = "qwen3vl_32b_minimax_h3_int8_convrot.safetensors";
      directory = "text_encoders";
      url = "https://huggingface.co/DutchGerman/comfyui-nix-flake/resolve/main/qwen3vl_32b_minimax_h3_int8_convrot.safetensors";
      sha256 = "bc2ced0fbea64757fa9acddccfc0b3f4819d1dcf1da6c124d690d368be283923";
      required = true;
    }
    {
      provider = "huggingface";
      name = "minimax_h3_audio_vae_fp32.safetensors";
      directory = "vae";
      url = "https://huggingface.co/DutchGerman/comfyui-nix-flake/resolve/main/minimax_h3_audio_vae_fp32.safetensors";
      sha256 = "8e505d95dd1561d47abd43d4238fd40d9bb1ae9e147ed0a4cba778d76ae4db48";
      required = true;
    }
    {
      provider = "huggingface";
      name = "minimax_h3_video_vae_fp16.safetensors";
      directory = "vae";
      url = "https://huggingface.co/DutchGerman/comfyui-nix-flake/resolve/main/minimax_h3_video_vae_fp16.safetensors";
      sha256 = "7c1f131492e7eddacaac9069a61b81bdd39de5cc96561e677c5eab1cdce5e522";
      required = true;
    }
    {
      provider = "huggingface";
      name = "minimax_h3_fl2va_pruned_int8_convrot.safetensors";
      directory = "diffusion_models";
      url = "https://huggingface.co/DutchGerman/comfyui-nix-flake/resolve/main/minimax_h3_fl2va_pruned_int8_convrot.safetensors";
      sha256 = "e889202c41dafb67b10d67b97f0d8541508036a6090af23425a5c2615d03c47a";
      required = true;
    }
    {
      provider = "huggingface";
      name = "minimax_h3_ref2va_pruned_int8_convrot.safetensors";
      directory = "diffusion_models";
      url = "https://huggingface.co/DutchGerman/comfyui-nix-flake/resolve/main/minimax_h3_ref2va_pruned_int8_convrot.safetensors";
      sha256 = "9255f52b6677845ad238f20dfaafa94727053694127ab7f255c048f0f9365779";
      required = true;
    }
    {
      provider = "huggingface";
      name = "minimax_h3_turbo_v4_step600_ema_pruned_comfyui.safetensors";
      directory = "loras";
      url = "https://huggingface.co/DutchGerman/comfyui-nix-flake/resolve/main/minimax_h3_turbo_v4_step600_ema_pruned_comfyui.safetensors";
      sha256 = "7098acf3ee75028fd9fcd948f50fcc8d995057fabb76f86bd3ca2c0ffc58e409";
      required = true;
    }
    {
      provider = "huggingface";
      name = "minimax_h3_t1_image_vae_step1597.safetensors";
      directory = "vae";
      url = "https://huggingface.co/DutchGerman/comfyui-nix-flake/resolve/main/minimax_h3_t1_image_vae_step1597.safetensors";
      sha256 = "6c3d0bfa055986a803a566a862fcde283a1e63db62829e5ef4a2a5aebf50bb86";
      required = true;
    }
    {
      provider = "huggingface";
      name = "taeh3.safetensors";
      directory = "vae_approx";
      url = "https://huggingface.co/DutchGerman/comfyui-nix-flake/resolve/main/taeh3.safetensors";
      sha256 = "f0f60fa072089997f817402098c2fd90777cb2660dd79cf5df42fc1e3e08e527";
      required = true;
    }
    {
      provider = "huggingface";
      name = "minimax_h3_latent_upscaler_3d_fp16.safetensors";
      directory = "latent_upscale_models";
      url = "https://huggingface.co/DutchGerman/comfyui-nix-flake/resolve/main/minimax_h3_latent_upscaler_3d_fp16.safetensors";
      sha256 = "043e5a48e161610ef6c3ea974645220354d06fa618abca15f76d084812eb55c2";
      required = true;
    }
    {
      provider = "huggingface";
      name = "sam3.1_multiplex_fp16.safetensors";
      directory = "checkpoints";
      url = "https://huggingface.co/DutchGerman/comfyui-nix-flake/resolve/main/sam3.1_multiplex_fp16.safetensors";
      sha256 = "9ba99c92703c2e8b4f47de2d34a539bb8e18923049e238b780d70dbe6368eb03";
      required = true;
    }
  ];

  workflows = [ ];

  customNodes = [
    {
      name = "ComfyUI-Manager";
      source = pkgs.fetchgit {
        url = "https://github.com/ltdrdata/ComfyUI-Manager.git";
        rev = "4c50a2bc8b9e684d8a85930567957470b952bebe";
        hash = "sha256-KxIcn4AQG4x17R3vD70JACeDZvKcExcmBYaFn1IH+xg=";
      };
    }
    {
      name = "rgthree-comfy";
      source = pkgs.fetchgit {
        url = "https://github.com/rgthree/rgthree-comfy.git";
        rev = "bc48c6aaeca87bedbc14245d89f9bc6be37a630e";
        hash = "sha256-yYX6Io28BNgzYB0Etit/HWu26XDR1akJ/nEsNmZYlPE=";
      };
    }
    {
      name = "ComfyUI-KJNodes";
      source = pkgs.fetchgit {
        url = "https://github.com/kijai/ComfyUI-KJNodes.git";
        rev = "ab72eda7ffad6280422d71ab7d54d3fb87c0ba18";
        hash = "sha256-FKBKcB3thkQ4UdTJQnGSatX0QYiN1VTvVBBTgDrmCCE=";
      };
    }
    {
      name = "ComfyUI-VideoHelperSuite";
      source = pkgs.fetchgit {
        url = "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git";
        rev = "4d907bee61e92c2e65af3bd6383a4e4d356126d1";
        hash = "sha256-unh8GH5qdN+U9IgwWFl6/eAZfq9j3fxHC1UVb+ZTlS4=";
      };
    }
    {
      name = "ComfyUI-Spectrum-MiniMax-H3";
      source = pkgs.fetchgit {
        url = "https://github.com/xmarre/ComfyUI-Spectrum-MiniMax-H3.git";
        rev = "806fe498d574a726fecb8818917f00a4b993fd77";
        hash = "sha256-wjl5wQNmHJczWCftOLqSGaK0PtD4ePBxEIUM9L2UsbI=";
      };
    }
    {
      name = "ComfyUI-MiniMaxH3-Director";
      source = pkgs.fetchgit {
        url = "https://github.com/seesee75-commits/ComfyUI-MiniMaxH3-Director.git";
        rev = "6664d75f459d06a9672ac8fbf28ffec59fbaf71a";
        hash = "sha256-Owc470VkyakiQ4VPmEWQwgWxDzC7WXOEVGMZSaTDkAw=";
      };
    }
    {
      name = "ComfyUI-Fantastic-MiniMaxH3-PromptBuilder";
      source = pkgs.fetchgit {
        url = "https://github.com/Adudeguyman/ComfyUI-Fantastic-MiniMaxH3-PromptBuilder.git";
        rev = "22e719fe89336c628383363182a4da3cb58d4f9b";
        hash = "sha256-i+r9Yiu0hvN2s4sPhZ1bKjrqR+xbpqgSKrC8ePfaNPc=";
      };
    }
    {
      name = "ComfyUi-Scale-Image-to-Total-Pixels-Advanced";
      source = pkgs.fetchgit {
        url = "https://github.com/BigStationW/ComfyUi-Scale-Image-to-Total-Pixels-Advanced.git";
        rev = "6888b7e6fcdb0e483f217648d0d4b0e0c22a72ba";
        hash = "sha256-iSFsdDAVuf5YOKRs7TTrgikxSw5PlsATok9CSjFsNUY=";
      };
    }
    {
      name = "ComfyUI-MiniMaxH3-T1-Latent";
      source = pkgs.fetchgit {
        url = "https://github.com/aitrepreneur/ComfyUI-MiniMaxH3-T1-Latent.git";
        rev = "6f55b2932713029b1547f3def8ae4e5c60f4e6ee";
        hash = "sha256-CT3D1glCy4Xc0by6cR1Q0ra//coYE/OGu0yRjjbcrF0=";
      };
    }
    {
      name = "ComfyUI-H3-Motion-Context-MultiRef";
      source = pkgs.fetchgit {
        url = "https://github.com/Aitrepreneur/ComfyUI-H3-Motion-Context-MultiRef-V3.git";
        rev = "d299ea552d49213e25a337f6e2f24fbf64e78f40";
        hash = "sha256-X5IjCTYSldp+xUy733ircdlu0PD/wIqzwzRE5ZyzXvI=";
      };
    }
    {
      name = "MaskVidExperiments";
      source = pkgs.fetchgit {
        url = "https://github.com/drozbay/MaskVidExperiments.git";
        rev = "c32ed8c17e6fe892a174ebf25fe98b1317de97fb";
        hash = "sha256-aR9569hhUStUFe2ec5d1fD544lOkjDRmGNRzZXHByI0=";
      };
    }
    {
      name = "ComfyUI-NKD-Basic-Tools";
      source = pkgs.fetchgit {
        url = "https://github.com/Nekodificador/ComfyUI-NKD-Basic-Tools.git";
        rev = "726d727217a15a469319731d9a17a66159435557";
        hash = "sha256-3zAyhsGrkpHxfn/C0IoglxTuXwwhK/Ih/eAECz88eUA=";
      };
    }
    {
      name = "Comfyui_Minimax_h3_latent_Upscaler";
      source = pkgs.fetchgit {
        url = "https://github.com/LBH-123-AI/Comfyui_Minimax_h3_latent_Upscaler.git";
        rev = "40316cf008b2fd8663263270669eb4da23f89d2c";
        hash = "sha256-ImddkqVBZd/IL0zB4yjhmRkvLmATAjZXJn1QIe2Yqd4=";
      };
    }
  ];

  inputAssets = [ ];
  runtime = {
    extraArgs = [ "--enable-cors-header" "--use-sage-attention" ];
  };
  dependencies = {
    python = [ ];
    customNodes = [ ];
  };
}
