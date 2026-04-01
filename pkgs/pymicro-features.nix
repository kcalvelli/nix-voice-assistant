{ lib, python3Packages, autoPatchelfHook, stdenv, fetchurl }:

let
  sources = {
    x86_64-linux = {
      url = "https://files.pythonhosted.org/packages/aa/30/a31c5dc56015e55f897d0beb71447f1e10f0062067258856f3735ede133a/pymicro_features-2.0.2-cp39-abi3-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl";
      hash = "sha256-ZadqfHhR7g3WCD3aVrg1q53G7d6vEbNEYXlXWN6EbQ8=";
    };
    aarch64-linux = {
      url = "https://files.pythonhosted.org/packages/cf/34/c52065f422c009d99c434fb68918142b815055942fcb57c9533810a22080/pymicro_features-2.0.2-cp39-abi3-manylinux_2_27_aarch64.manylinux_2_28_aarch64.whl";
      hash = "sha256-rOrTY4a0KTTmIPV9dIEXe6Rh3eJHzM72qEb1gxgF5sc=";
    };
  };
in
python3Packages.buildPythonPackage rec {
  pname = "pymicro-features";
  version = "2.0.2";
  format = "wheel";

  src = fetchurl sources.${stdenv.hostPlatform.system};

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib # libstdc++
  ];

  pythonImportsCheck = [ "pymicro_features" ];

  meta = {
    description = "Speech features using TFLite Micro audio frontend";
    homepage = "https://github.com/OHF-Voice/pymicro-wakeword";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
