{ basePkgs }:
let
  pythonPackages = basePkgs.python313Packages;
  wheel =
    { pname, version, url, hash, dependencies ? [ ], pythonRemoveDeps ? [ ] }:
    pythonPackages.buildPythonPackage {
      inherit pname version dependencies pythonRemoveDeps;
      format = "wheel";
      nativeBuildInputs = [ basePkgs.patchelf ];
      src = basePkgs.fetchurl { inherit url hash; };
      postFixup = ''
        find "$out/${pythonPackages.python.sitePackages}" -type f \( -name '*.so' -o -name '*.so.*' \) \
          -exec ${basePkgs.patchelf}/bin/patchelf --add-rpath "${basePkgs.stdenv.cc.cc.lib}/lib" {} +
      '';
      passthru.cudaSupport = pname == "torch";
    };
  cudaPathfinder = wheel {
    pname = "cuda-pathfinder";
    version = "1.1.0";
    url =
      "https://files.pythonhosted.org/packages/52/07/7978a4c4d8e70620170aa247ce16241a72d4cf6e4336bd3b296926baf7df/cuda_pathfinder-1.1.0-py3-none-any.whl";
    hash = "sha256-Pmb+Cvjq0g7KJeB30uDLLcwCfUKX1VCnT5mgIR5hB5k=";
  };
  cudaBindings = wheel {
    pname = "cuda-bindings";
    version = "13.0.3";
    url =
      "https://files.pythonhosted.org/packages/ab/ac/699889100536f1b63779646291e74eefa818087a0974eb271314d850f5dc/cuda_bindings-13.0.3-cp313-cp313-manylinux_2_24_x86_64.manylinux_2_28_x86_64.whl";
    hash = "sha256-US0NgDpeR6ikLVo0zgkygCv3L+lS/bEax5hxWjXG5cs=";
    dependencies = [ cudaPathfinder ];
  };
  cudaRuntime = wheel {
    pname = "nvidia-cuda-runtime";
    version = "13.0.96";
    url =
      "https://files.pythonhosted.org/packages/2e/24/d1558f3b68b1d26e706813b1d10aa1d785e4698c425af8db8edc3dced472/nvidia_cuda_runtime-13.0.96-py3-none-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
    hash = "sha256-f4IlDXeCqiO2z+dl7MfbVUvTwocMQ/PRgh8dGK6/BUg=";
  };
  cudaCufft = wheel {
    pname = "nvidia-cufft";
    version = "12.0.0.61";
    url =
      "https://files.pythonhosted.org/packages/a8/2f/7b57e29836ea8714f81e9898409196f47d772d5ddedddf1592eadb8ab743/nvidia_cufft-12.0.0.61-py3-none-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
    hash = "sha256-bET2ktzo/V/9Pj3xNLbNucL3LZnPQLYsMt3kXuqd2tM=";
    dependencies = [ cudaNvjitlink ];
  };
  cudaCufile = wheel {
    pname = "nvidia-cufile";
    version = "1.15.1.6";
    url =
      "https://files.pythonhosted.org/packages/3f/70/4f193de89a48b71714e74602ee14d04e4019ad36a5a9f20c425776e72cd6/nvidia_cufile-1.15.1.6-py3-none-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
    hash = "sha256-CKPs765aAcf1EXNRxk8Xx8Yu+l//2+JPx9KY2hnNC0Q=";
  };
  cudaCupti = wheel {
    pname = "nvidia-cuda-cupti";
    version = "13.0.85";
    url =
      "https://files.pythonhosted.org/packages/33/6d/737d164b4837a9bbd202f5ae3078975f0525a55730fe871d8ed4e3b952b0/nvidia_cuda_cupti-13.0.85-py3-none-manylinux_2_25_x86_64.whl";
    hash = "sha256-TrAcCOhZv5JNIiJQ0uj4uP9tPbRyEojPNdFCUqTZM8g=";
  };
  cudaCurand = wheel {
    pname = "nvidia-curand";
    version = "10.4.0.35";
    url =
      "https://files.pythonhosted.org/packages/a5/9f/be0a41ca4a4917abf5cb9ae0daff1a6060cc5de950aec0396de9f3b52bc5/nvidia_curand-10.4.0.35-py3-none-manylinux_2_27_x86_64.whl";
    hash = "sha256-Gu4zpdpuHbCD/iuQCC3viRXzDzJI1YlrzsNqV52UG/w=";
  };
  cudaCusolver = wheel {
    pname = "nvidia-cusolver";
    version = "12.0.4.66";
    url =
      "https://files.pythonhosted.org/packages/5f/67/cba3777620cdacb99102da4042883709c41c709f4b6323c10781a9c3aa34/nvidia_cusolver-12.0.4.66-py3-none-manylinux_2_27_x86_64.whl";
    hash = "sha256-CnWdpd6lwOoQ/TB951zetZ5+pPy4rdCSSFm5RLq/ERI=";
    dependencies = [ cudaCublas cudaNvjitlink cudaCusparse ];
  };
  cudaCusparse = wheel {
    pname = "nvidia-cusparse";
    version = "12.6.3.3";
    url =
      "https://files.pythonhosted.org/packages/fa/18/623c77619c31d62efd55302939756966f3ecc8d724a14dab2b75f1508850/nvidia_cusparse-12.6.3.3-py3-none-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
    hash = "sha256-KzyJyI0B7g5HfLf4LvYKEaS81Xtrh8M/eJNQtZdZNgs=";
    dependencies = [ cudaNvjitlink ];
  };
  cudaNvjitlink = wheel {
    pname = "nvidia-nvjitlink";
    version = "13.0.88";
    url =
      "https://files.pythonhosted.org/packages/56/7a/123e033aaff487c77107195fa5a2b8686795ca537935a24efae476c41f05/nvidia_nvjitlink-13.0.88-py3-none-manylinux2010_x86_64.manylinux_2_12_x86_64.whl";
    hash = "sha256-E6dPQp4juSHBEJl2q++sxpg18vQz69Mj05RuEdgE5Hs=";
  };
  cudaNvrtc = wheel {
    pname = "nvidia-cuda-nvrtc";
    version = "13.0.88";
    url =
      "https://files.pythonhosted.org/packages/c3/68/483a78f5e8f31b08fb1bb671559968c0ca3a065ac7acabfc7cee55214fd6/nvidia_cuda_nvrtc-13.0.88-py3-none-manylinux2010_x86_64.manylinux_2_12_x86_64.whl";
    hash = "sha256-rZttLq0kNfEcu2hogJ0q3u7jAum7lLzwU5x6QNgOhXU=";
  };
  cudaNvtx = wheel {
    pname = "nvidia-nvtx";
    version = "13.0.85";
    url =
      "https://files.pythonhosted.org/packages/c2/f3/d86c845465a2723ad7e1e5c36dcd75ddb82898b3f53be47ebd429fb2fa5d/nvidia_nvtx-13.0.85-py3-none-manylinux1_x86_64.manylinux_2_5_x86_64.whl";
    hash = "sha256-STbR1ngPvmjbRU9ecqQv9k0f1jl+9fNjrnhpMP1cHNQ=";
  };
  cudaCublas = wheel {
    pname = "nvidia-cublas";
    version = "13.1.0.3";
    url =
      "https://files.pythonhosted.org/packages/e7/44/423ac00af4dd95a5aeb27207e2c0d9b7118702149bf4704c3ddb55bb7429/nvidia_cublas-13.1.0.3-py3-none-manylinux_2_27_x86_64.whl";
    hash = "sha256-7ociwfAUWrJGvMueRSFTteBRX9CUw2eN9QsqCIi4sXE=";
  };
  cudaCudnn = wheel {
    pname = "nvidia-cudnn-cu13";
    version = "9.20.0.48";
    url =
      "https://files.pythonhosted.org/packages/6e/5e/edb9c0ae051602c3ccaffe424256463636d639e27d7f302dde9975ef9e7a/nvidia_cudnn_cu13-9.20.0.48-py3-none-manylinux_2_27_x86_64.whl";
    hash = "sha256-DEXdjutQtgPweZWxswDGL/5qGYBIK4KzvPlKTKnUkwQ=";
    dependencies = [ cudaCublas ];
  };
  cudaCusparselt = wheel {
    pname = "nvidia-cusparselt-cu13";
    version = "0.8.1";
    url =
      "https://files.pythonhosted.org/packages/34/7d/2661f2fb3ac4302f3a246f5fc030213ac60c1fe0bce84f9783dbd831dbb7/nvidia_cusparselt_cu13-0.8.1-py3-none-manylinux2014_x86_64.whl";
    hash = "sha256-eGzodWjDA/rbWvzHEC1FTNMEDXX2+GJvXbRg0YcfTdA=";
  };
  cudaNccl = wheel {
    pname = "nvidia-nccl-cu13";
    version = "2.29.7";
    url =
      "https://files.pythonhosted.org/packages/67/f4/58e4e91b6919367c7aafb8e36fce9aad1a3047e536bf7e2fd560927d3a4c/nvidia_nccl_cu13-2.29.7-py3-none-manylinux_2_18_x86_64.whl";
    hash = "sha256-7dgVOERnhuw7c5clQ+U7tDvK8L/I73bLZ5/MOQ/+E20=";
  };
  cudaNvshmem = wheel {
    pname = "nvidia-nvshmem-cu13";
    version = "3.4.5";
    url =
      "https://files.pythonhosted.org/packages/3c/35/a9bf80a609e74e3b000fef598933235c908fcefcef9026042b8e6dfde2a9/nvidia_nvshmem_cu13-3.4.5-py3-none-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
    hash = "sha256-KQ8KLulMnzaHoCUC87kpmp+f6Cbm0Ch+4YSC541JW4A=";
  };
  triton = wheel {
    pname = "triton";
    version = "3.7.1";
    url =
      "https://files.pythonhosted.org/packages/07/42/2c3ac59253ae8892b6f307875263dd23dc875cdf732d3aea40d6d41fb7cb/triton-3.7.1-cp313-cp313-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl";
    hash = "sha256-WMDhMdoFE0oqR4jMvMDBEFzw9UyOmPGeNM1GU5bcFes=";
  };
  torch = pythonPackages.buildPythonPackage {
    pname = "torch";
    version = "2.12.1+cu130";
    format = "other";
    dontUnpack = true;
    nativeBuildInputs = [ basePkgs.patchelf basePkgs.unzip ];
    buildInputs = [ basePkgs.stdenv.cc.cc.lib ];
    src = basePkgs.fetchurl {
      url =
        "https://download-r2.pytorch.org/whl/cu130/torch-2.12.1%2Bcu130-cp313-cp313-manylinux_2_28_x86_64.whl";
      hash = "sha256-1eGEBELSGClXs9L3eMwyXJD6XLQqqLGslJ8CnpvdfwY=";
    };
    dependencies = [
      cudaBindings
      cudaCublas
      cudaCudnn
      cudaCufft
      cudaCufile
      cudaCupti
      cudaCurand
      cudaCusolver
      cudaCusparse
      cudaCusparselt
      cudaNccl
      cudaNvjitlink
      cudaNvrtc
      cudaNvshmem
      cudaNvtx
      cudaRuntime
      pythonPackages.filelock
      pythonPackages.fsspec
      pythonPackages.jinja2
      pythonPackages.networkx
      pythonPackages.setuptools
      pythonPackages.sympy
      pythonPackages.typing-extensions
      triton
    ];
    dontUsePythonCatchConflicts = true;
    installPhase = ''
      mkdir -p "$out/${pythonPackages.python.sitePackages}"
      ${basePkgs.unzip}/bin/unzip -q "$src" -d "$out/${pythonPackages.python.sitePackages}"
      ${basePkgs.gnused}/bin/sed -i -E \
        '/^Requires-Dist: (setuptools<82|cuda-toolkit|nvidia-cublas|cuda-bindings|nvidia-cudnn-cu13|nvidia-cusparselt-cu13|nvidia-nccl-cu13|nvidia-nvshmem-cu13|triton)/d' \
        "$out/${pythonPackages.python.sitePackages}/torch-2.12.1+cu130.dist-info/METADATA"
    '';
    postFixup = ''
      find "$out/${pythonPackages.python.sitePackages}" -type f \( -name '*.so' -o -name '*.so.*' \) \
        -exec ${basePkgs.patchelf}/bin/patchelf --add-rpath "${basePkgs.stdenv.cc.cc.lib}/lib" {} +
    '';
    pythonImportsCheck = [ "torch" ];
    passthru.cudaSupport = true;
  };
  torchvision = pythonPackages.buildPythonPackage {
    pname = "torchvision";
    version = "0.27.1+cu130";
    format = "wheel";
    src = basePkgs.fetchurl {
      url =
        "https://download-r2.pytorch.org/whl/cu130/torchvision-0.27.1%2Bcu130-cp313-cp313-manylinux_2_28_x86_64.whl";
      hash = "sha256-+fAI1LGy8BPq977Bqf8iEmNYHXdmjU4eDpw+01HVZGU=";
    };
    dependencies = with pythonPackages; [ numpy pillow torch ];
    passthru.cudaSupport = true;
    pythonImportsCheck = [ "torchvision" ];
  };
  cudaPython = basePkgs.python313.override {
    packageOverrides = final: prev: { inherit torch torchvision; };
  };
  pkgs = basePkgs // {
    python3 = cudaPython;
    comfyui = basePkgs.comfyui.override { python3 = cudaPython; };
  };
in {
  inherit pkgs torch torchvision;
  packages = {
    inherit torch torchvision;
    "cuda-python" = cudaPython.withPackages (ps: [ ps.torch ps.torchvision ]);
  };
  checks.cuda-enabled = pkgs.runCommand "comfyui-cuda-enabled" { } ''
    test "${
      if pkgs.comfyui.python.pkgs.torch.cudaSupport then "true" else "false"
    }" = true
    touch "$out"
  '';
}
