## Context

Packaging a third-party Python application (OHF-Voice/linux-voice-assistant) for NixOS. The app is a voice satellite for Home Assistant that combines wake word detection and audio streaming into one process, speaking ESPHome protocol. It replaces the two-service Wyoming stack (openwakeword + satellite) currently deployed on edge.nix.

Current state: The app has Docker packaging only. No Nix packaging exists. Two of its Python dependencies (`pymicro-wakeword`, `python-mpv`) are not in nixpkgs.

## Goals / Non-Goals

**Goals:**
- Buildable Nix package with all dependencies resolved
- NixOS module with declarative config mapping to CLI args
- Drop-in replacement for Wyoming satellite + openwakeword services on edge.nix

**Non-Goals:**
- Upstream contributions or patches
- ARM/aarch64 support
- Replacing Wyoming Whisper (STT) on mini

## Decisions

**Python version: 3.13** — Upstream supports 3.11-3.13. Use 3.13 to match nixpkgs current default. Most deps already available as `python313Packages.*`.

**`buildPythonApplication` not `buildPythonPackage`** — This is an end-user application with a CLI entry point, not a library. `buildPythonApplication` is the correct builder.

**Data files installed to `$out/share/`** — The upstream code uses `Path(__file__).parent.parent / "sounds"` and `"wakewords"` which resolves to `site-packages/` in a proper install — wrong. Rather than patching the source, we install data to `$out/share/linux-voice-assistant/{sounds,wakewords}` and pass explicit `--wakeup-sound`, `--wake-word-dir` etc. via the NixOS module. CLI args override the broken defaults.

**`python-mpv` wrapping strategy** — `python-mpv` uses `ctypes.util.find_library("mpv")` at runtime. Wrap the main binary with `LD_LIBRARY_PATH` pointing to `${mpv}/lib` rather than patching the library. Standard Nix pattern for ctypes wrappers.

**Source pinning** — `fetchFromGitHub` with a specific `rev` (commit hash on `main`). Updated manually. No flake input for upstream — it's not a flake.

**Systemd user service** — Runs as the configured user, needs access to PipeWire/PulseAudio socket at `/run/user/<uid>/pulse/native`. Set `XDG_RUNTIME_DIR` in the service environment.

## Risks / Trade-offs

**Alpha upstream** — Breaking changes possible. Pinning to a commit mitigates; updates are intentional.

**`soundcard` PipeWire compatibility** — The `soundcard` library accesses audio through PulseAudio protocol. PipeWire's PulseAudio compatibility layer should work but is untested in this context. If it doesn't, `PULSE_SERVER` env var may need to be set.

**Hardcoded wake word threshold (0.5)** — Lower than the 0.7 used in Wyoming config. May cause more false triggers. Accept for now; hardware AEC on eMeet helps.
