{ lib
, python3Packages
, fetchFromGitHub
, pymicro-features
, pymicro-wakeword
, python-mpv
}:

python3Packages.buildPythonApplication rec {
  pname = "linux-voice-assistant";
  version = "0-unstable-2025-03-31";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "OHF-Voice";
    repo = "linux-voice-assistant";
    rev = "341e3dcb9ccbc16989b1053c0d297e900b8f6858";
    hash = "sha256-4De1FXd/AJjkOy/TmNIEvz6oBGVZOf1jh03lfoQpB8w=";
  };

  # setuptools-scm needs git history for versioning; provide it statically
  env.SETUPTOOLS_SCM_PRETEND_VERSION = "0.0.0";

  build-system = [
    python3Packages.setuptools
    python3Packages.setuptools-scm
  ];

  dependencies = [
    python3Packages.aioesphomeapi
    python3Packages.netifaces2
    python3Packages.soundcard
    python3Packages.numpy
    pymicro-features
    pymicro-wakeword
    python3Packages.pyopen-wakeword
    python-mpv
    python3Packages.zeroconf
    python3Packages.getmac
    python3Packages.types-protobuf
  ];

  # Install bundled data files (sounds, wakewords) to share/
  postInstall = ''
    mkdir -p $out/share/linux-voice-assistant
    cp -r $src/sounds $out/share/linux-voice-assistant/
    cp -r $src/wakewords $out/share/linux-voice-assistant/
  '';

  # Upstream pins aioesphomeapi==42.7.0 but nixpkgs has a newer version;
  # relax the check since the API is compatible
  pythonRelaxDeps = [ "aioesphomeapi" ];

  # Don't run tests during build (they require audio hardware)
  doCheck = false;

  pythonImportsCheck = [ "linux_voice_assistant" ];

  meta = {
    description = "Voice assistant for Home Assistant using the ESPHome protocol";
    homepage = "https://github.com/OHF-Voice/linux-voice-assistant";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "linux-voice-assistant";
  };
}
