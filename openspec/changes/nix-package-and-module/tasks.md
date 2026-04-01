## 1. Custom Python Derivations

- [x] 1.1 Create `pymicro-wakeword` derivation — fetch from PyPI, build with native deps
- [x] 1.2 Create `python-mpv` derivation — pure Python, propagate libmpv runtime dep

## 2. Main Package Derivation

- [x] 2.1 Create `linux-voice-assistant` derivation using `buildPythonApplication` with all deps, install sounds/wakewords to `$out/share/`, wrap binary with libmpv on LD_LIBRARY_PATH

## 3. Flake

- [x] 3.1 Create `flake.nix` with nixpkgs input, package output, NixOS module output, pin upstream to a specific commit on main

## 4. NixOS Module

- [x] 4.1 Create NixOS module with service options (enable, user, name, host, port, audioInputDevice, audioOutputDevice, wakeModel, wakeWordDirs, debug, openFirewall, extraArgs)
- [x] 4.2 Systemd unit: ExecStart builds CLI from options, sets XDG_RUNTIME_DIR, After=network-online.target+pipewire.service, PrivateDevices=false, restart on failure

## 5. Verify

- [x] 5.1 Run `nix build` and confirm package builds
- [x] 5.2 Confirm `$out/bin/linux-voice-assistant --help` works and bundled data files exist
