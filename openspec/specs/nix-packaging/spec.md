# nix-packaging Specification

## Purpose
TBD - created by archiving change nix-package-and-module. Update Purpose after archive.
## Requirements
### Requirement: Package builds from upstream source
The flake SHALL produce a working `linux-voice-assistant` binary from the OHF-Voice/linux-voice-assistant repository pinned to a specific commit on `main`.

#### Scenario: Clean build
- **WHEN** `nix build .#linux-voice-assistant` is run
- **THEN** the package builds successfully and `$out/bin/linux-voice-assistant --help` prints usage

#### Scenario: Runtime library access
- **WHEN** `linux-voice-assistant` is executed
- **THEN** `libmpv` is available on the library path and `python-mpv` can load it

### Requirement: Bundled data files are accessible
The package SHALL install `sounds/` and `wakewords/` from the upstream repo to `$out/share/linux-voice-assistant/`.

#### Scenario: Sound files present
- **WHEN** the package is built
- **THEN** `$out/share/linux-voice-assistant/sounds/wake_word_triggered.flac` exists

#### Scenario: Wake word models present
- **WHEN** the package is built
- **THEN** `$out/share/linux-voice-assistant/wakewords/` contains `.tflite` and `.json` model files

### Requirement: NixOS module provides declarative service configuration
The flake SHALL export a NixOS module at `nixosModules.linux-voice-assistant` that creates a systemd service with declarative options.

#### Scenario: Minimal enable
- **WHEN** `services.linux-voice-assistant.enable = true;` is set
- **THEN** a `linux-voice-assistant` systemd service is created with default settings (port 6053, auto-detected host/network)

#### Scenario: Full configuration
- **WHEN** options like `name`, `port`, `audioInputDevice`, `wakeModel`, `wakeWordDirs` are set
- **THEN** the systemd ExecStart command includes the corresponding `--name`, `--port`, `--audio-input-device`, `--wake-model`, `--wake-word-dir` CLI args

### Requirement: Service runs with audio access
The systemd service SHALL run as the configured user with access to the PipeWire/PulseAudio socket.

#### Scenario: PipeWire audio access
- **WHEN** the service starts
- **THEN** `XDG_RUNTIME_DIR` is set to `/run/user/<uid>` and the process can access the audio socket

#### Scenario: Device access
- **WHEN** the service starts
- **THEN** `PrivateDevices` is disabled so ALSA/audio devices are accessible

### Requirement: Firewall opens ESPHome API port
The module SHALL optionally open the configured port in the NixOS firewall.

#### Scenario: Default port
- **WHEN** `openFirewall = true` and no custom port is set
- **THEN** TCP port 6053 is opened in the firewall

#### Scenario: Custom port
- **WHEN** `openFirewall = true` and `port = 7053`
- **THEN** TCP port 7053 is opened in the firewall

### Requirement: Custom Python dependencies build successfully
`pymicro-wakeword` and `python-mpv` SHALL have working Nix derivations.

#### Scenario: pymicro-wakeword builds
- **WHEN** `nix build .#pymicro-wakeword` is run
- **THEN** the package builds including its native C extensions

#### Scenario: python-mpv builds
- **WHEN** `nix build .#python-mpv` is run
- **THEN** the package builds as a pure Python package

