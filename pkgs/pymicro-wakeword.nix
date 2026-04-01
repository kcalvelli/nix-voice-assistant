{ lib, python3Packages, autoPatchelfHook, stdenv, pymicro-features, fetchurl }:

python3Packages.buildPythonPackage rec {
  pname = "pymicro-wakeword";
  version = "2.2.1";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/e8/c7/33c80411d374577b2eb81465d1aa53b41449adc333cb5b05341334e57792/pymicro_wakeword-2.2.1-py3-none-manylinux_2_35_x86_64.whl";
    hash = "sha256-4AYpvS6FMh0wy4lnAiaoUxajnfUOveTu3V60yLuUAU0=";
  };

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
    platforms = [ "x86_64-linux" ];
  };
}
