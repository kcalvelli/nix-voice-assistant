{ lib, python3Packages, autoPatchelfHook, stdenv, pymicro-features, fetchurl }:

let
  sources = {
    x86_64-linux = {
      url = "https://files.pythonhosted.org/packages/e8/c7/33c80411d374577b2eb81465d1aa53b41449adc333cb5b05341334e57792/pymicro_wakeword-2.2.1-py3-none-manylinux_2_35_x86_64.whl";
      hash = "sha256-4AYpvS6FMh0wy4lnAiaoUxajnfUOveTu3V60yLuUAU0=";
    };
    aarch64-linux = {
      url = "https://files.pythonhosted.org/packages/1d/5a/0c9d60a1c8c2c2d7b9746e8b27b7980236da9980f77c62421937a779eda0/pymicro_wakeword-2.2.1-py3-none-manylinux_2_35_aarch64.whl";
      hash = "sha256-uCt//saJhlslpr8nOO/ZxvQlWyLNq19k+dGnYISt82Y=";
    };
  };
in
python3Packages.buildPythonPackage rec {
  pname = "pymicro-wakeword";
  version = "2.2.1";
  format = "wheel";

  src = fetchurl sources.${stdenv.hostPlatform.system};

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib # libstdc++
  ];

  dependencies = [
    pymicro-features
    python3Packages.numpy
  ];

  pythonImportsCheck = [ "pymicro_wakeword" ];

  meta = {
    description = "Wake word detection using TFLite Micro";
    homepage = "https://github.com/OHF-Voice/pymicro-wakeword";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
