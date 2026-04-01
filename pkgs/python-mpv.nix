{ lib, python3Packages, mpv, fetchurl }:

python3Packages.buildPythonPackage rec {
  pname = "python-mpv";
  version = "1.0.8";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/22/f3/4c632eaacebfc62ab9414586137aecf6c0ea2a1e99708cf5a4c0dec13ae0/python_mpv-1.0.8-py3-none-any.whl";
    hash = "sha256-tSlkA+mQ+3NI30yiIRk3oDD1JL9jhle9p+RaALwt8M0=";
  };

  # python-mpv uses ctypes.util.find_library("mpv") at runtime
  # Patch it to use the absolute path to libmpv
  postInstall = ''
    site="$out/lib/${python3Packages.python.libPrefix}/site-packages"
    substituteInPlace "$site/mpv.py" \
      --replace-fail \
        "sofile = ctypes.util.find_library('mpv')" \
        "sofile = '${mpv}/lib/libmpv.so'"
  '';

  pythonImportsCheck = [ "mpv" ];

  meta = {
    description = "Python interface to the mpv media player";
    homepage = "https://github.com/jaseg/python-mpv";
    license = lib.licenses.lgpl21Plus;
    platforms = lib.platforms.linux;
  };
}
