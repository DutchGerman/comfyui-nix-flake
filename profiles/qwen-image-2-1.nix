{ pkgs }:
{
  name = "qwen-image-2-1";

  models = [
    {
      provider = "huggingface";
      name = "qwen_image_2.1_int8_convrot.safetensors";
      directory = "diffusion_models";
      url = "https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main/diffusion_models/qwen_image_2.1_int8_convrot.safetensors";
      sha256 = "cb74113cb03faecd79611b01fd7fd642f0aa60d6f0b95086abee214d75eaa57d";
      required = true;
    }
    {
      provider = "huggingface";
      name = "qwen3vl_8b_int8_convrot.safetensors";
      directory = "text_encoders";
      url = "https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main/text_encoders/qwen3vl_8b_int8_convrot.safetensors";
      sha256 = "8bfd0f6e12abf2d2d697ecc888e5e90b0d6741d6708f05799f53afa560452e8f";
      required = true;
    }
    {
      provider = "huggingface";
      name = "qwen_image_2.1_vae_bf16.safetensors";
      directory = "vae";
      url = "https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main/vae/qwen_image_2.1_vae_bf16.safetensors";
      sha256 = "bb21f7473051e1ac368515dd3f2e15cd44d7a11748ee8823e1ddca3e4876b7c9";
      required = true;
    }
    {
      provider = "huggingface";
      name = "qwen3.5_9b_qwen_image_2.1_pe_t2i.int8_convrot.safetensors";
      directory = "text_encoders";
      url = "https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main/text_encoders/qwen3.5_9b_qwen_image_2.1_pe_t2i.int8_convrot.safetensors";
      sha256 = "9182abae56fe05459840a86d22abd21f972061c92fce032630af680c8c5178d3";
      required = false;
    }
  ];

  workflows = [
    {
      name = "qwen-image-2-1-t2i.json";
      source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/Comfy-Org/workflow_templates/main/templates/image_qwen_image_2_1_t2i.json";
        hash = "sha256-XytQ7q8n5WpFRWaBrVMZ3xrlEkPZZTrD+Sx9wF0eFQM=";
      };
    }
  ];

  customNodes = [ ];

  inputAssets = [ ];
}
