# Nix Package and NixOS Module for linux-voice-assistant

## Summary

Package [OHF-Voice/linux-voice-assistant](https://github.com/OHF-Voice/linux-voice-assistant) as a Nix flake providing both a package derivation and a NixOS module. This replaces the `services.wyoming.satellite` + `services.wyoming.openwakeword` pair on edge.nix with a single `services.linux-voice-assistant` service speaking ESPHome protocol.

## Motivation

The current Wyoming satellite setup requires two cooperating services and uses raw ALSA commands for audio. linux-voice-assistant consolidates wake word detection and satellite functionality into one process, uses the PipeWire-native `soundcard` library for audio, and speaks ESPHome protocol (auto-discovered by Home Assistant via mDNS) instead of the Wyoming protocol.

## Scope

### In scope

- **Flake** pinned to upstream `main` branch
- **Package derivation** (`packages.linux-voice-assistant`)
  - Python package built with setuptools
  - Bundled `sounds/` and `wakewords/` installed to `$out/share/`
  - Binary wrapped with `libmpv` on library path
  - Two custom Python derivations: `pymicro-wakeword`, `python-mpv`
- **NixOS module** (`nixosModules.linux-voice-assistant`)
  - Systemd service (user service, runs as configured user)
  - Declarative options mapping to CLI args (name, host, port, audio devices, wake model, wake word dirs, debug, extraArgs)
  - Firewall rule for ESPHome API port (default 6053)
  - tmpfiles for state dirs (preferences, downloaded wake words)
- **Wake word sidecar JSON** for `hey_yo_sid.tflite` (via tmpfiles or module config)

### Out of scope

- Upstream patches (threshold tuning, noise suppression, VAD, auto-gain)
- Home Assistant side configuration (ESPHome integration setup is manual)
- Custom wake word training
- ARM/aarch64 cross-compilation (desktop x86_64 only for now)

### Non-goals

- Replacing Wyoming Whisper on mini (STT stays as-is)
- Running as a container

## Approach

### 1. Custom Python derivations

**`pymicro-wakeword`** - Has C extensions (TFLite micro features). Needs:
- `buildPythonPackage` from PyPI source
- Build inputs: likely numpy, C compiler toolchain
- Investigate actual native deps from its `pyproject.toml`/`setup.py`

**`python-mpv`** - Pure Python ctypes wrapper. Needs:
- `buildPythonPackage` from PyPI source
- Runtime dep: `libmpv` (via `makeWrapperArgs` or propagated)

### 2. Main derivation

```
buildPythonApplication {
  pname = "linux-voice-assistant";
  src = upstream main branch (fetchFromGitHub);

  propagatedBuildInputs = [
    aioesphomeapi netifaces2 soundcard numpy
    pymicro-wakeword pyopen-wakeword python-mpv
    zeroconf getmac types-protobuf
  ];

  # Install data files
  postInstall = ''
    mkdir -p $out/share/linux-voice-assistant
    cp -r sounds wakewords $out/share/linux-voice-assistant/
  '';

  # Wrap with libmpv
  makeWrapperArgs = [ "--prefix LD_LIBRARY_PATH : ${libmpv}/lib" ];
}
```

### 3. NixOS module

Minimal option set:

| Option | Type | Maps to |
|--------|------|---------|
| `enable` | bool | - |
| `user` | str | systemd User= |
| `name` | str | `--name` |
| `host` | str | `--host` |
| `port` | int | `--port` |
| `audioInputDevice` | null or str | `--audio-input-device` |
| `audioOutputDevice` | null or str | `--audio-output-device` |
| `wakeModel` | str | `--wake-model` |
| `wakeWordDirs` | list of path | `--wake-word-dir` (repeated) |
| `debug` | bool | `--debug` |
| `extraArgs` | list of str | appended to CLI |

Systemd unit:
- `After=network-online.target pipewire.service`
- `Wants=network-online.target`
- `PrivateDevices=false` (needs audio device access)
- Environment: `XDG_RUNTIME_DIR=/run/user/<uid>` (for PipeWire socket)
- Restart on failure

### 4. Migration from Wyoming

On edge.nix:
- Remove `services.wyoming.openwakeword` and `services.wyoming.satellite`
- Remove `webrtc-noise-gain` overlay (no longer needed)
- Remove Wyoming-related systemd overrides and resume commands
- Add `services.linux-voice-assistant` config
- Update firewall: replace port 10700 with 6053
- Create `hey_yo_sid.json` sidecar alongside the `.tflite` model

On mini (Home Assistant):
- Add ESPHome integration to discover the device on port 6053
- Configure voice assistant pipeline to use the new satellite
- Wyoming Whisper stays unchanged

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| `soundcard` lib can't address eMeet by name through PipeWire | Can't select correct mic | Run `--list-input-devices` first; fall back to PipeWire default device routing |
| `pymicro-wakeword` has undocumented native build deps | Build failure | Inspect PyPI sdist before writing derivation |
| Upstream `main` breaks (alpha software) | Service broken on rebuild | Pin to specific commit, update intentionally |
| `_REPO_DIR` path assumptions in `__main__.py` | Default sound/wakeword paths wrong | Override all paths via CLI args in module; no patch needed |
| Wake word threshold hardcoded at 0.5 (was 0.7 in Wyoming) | More false triggers | Accept for now; eMeet hardware AEC helps; upstream may add config later |

## Open questions

1. What are `pymicro-wakeword`'s actual build dependencies? (Investigate PyPI sdist)
2. What does the eMeet show up as in `soundcard.all_microphones()`? (Discover at runtime after initial package build)
3. Does `hey_yo_sid.tflite` work with both openwakeword and micro-wakeword, or only one? (Check the model type to write the correct JSON sidecar)
