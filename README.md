# nix-voice-assistant

Nix flake packaging [OHF-Voice/linux-voice-assistant](https://github.com/OHF-Voice/linux-voice-assistant) for NixOS. Provides a package and NixOS module for running a voice satellite that speaks ESPHome protocol to Home Assistant.

Supports **x86_64-linux** and **aarch64-linux** (Raspberry Pi).

## What is this?

linux-voice-assistant is an all-in-one voice satellite for Home Assistant that combines:

- Local wake word detection (OpenWakeWord + MicroWakeWord)
- Audio capture and playback (via PipeWire/PulseAudio)
- ESPHome protocol (auto-discovered by Home Assistant via mDNS)
- Timers, media playback, volume control, mute toggle

It replaces the two-service Wyoming stack (wyoming-satellite + wyoming-openwakeword) with a single process.

## Quick start

Add the flake input to your NixOS configuration:

```nix
# flake.nix
inputs.linux-voice-assistant = {
  url = "github:kcalvelli/nix-voice-assistant";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Import the module and enable the service:

```nix
# configuration.nix
{
  imports = [ inputs.linux-voice-assistant.nixosModules.default ];

  services.linux-voice-assistant = {
    enable = true;
    user = "youruser"; # must have access to PipeWire/PulseAudio
    openFirewall = true;
  };
}
```

Home Assistant will auto-discover the device via the ESPHome integration.

## Configuration options

```nix
services.linux-voice-assistant = {
  enable = true;
  user = "youruser";
  name = "Kitchen Speaker";          # friendly name shown in HA
  host = "0.0.0.0";                  # bind address (auto-detected if null)
  port = 6053;                       # ESPHome API port
  networkInterface = null;           # for IP/MAC detection (auto-detected)
  audioInputDevice = null;           # mic name or index (see below)
  audioOutputDevice = null;          # mpv device name (see below)
  wakeModel = "okay_nabu";           # wake word model to use
  wakeWordDirs = [];                 # extra dirs with custom .tflite + .json models
  debug = false;
  openFirewall = false;
  extraArgs = [];                    # escape hatch for any CLI args
};
```

## Discovering audio devices

List available input devices (microphones):

```sh
nix run github:kcalvelli/nix-voice-assistant -- --list-input-devices
```

List available output devices (speakers):

```sh
nix run github:kcalvelli/nix-voice-assistant -- --list-output-devices
```

Use the printed names in `audioInputDevice` and `audioOutputDevice`.

## Custom wake words

To use a custom wake word model, create a `.tflite` model and a companion `.json` config:

```json
{
  "type": "openWakeWord",
  "wake_word": "hey computer",
  "model": "hey_computer.tflite",
  "trained_languages": ["en"]
}
```

Valid types: `"openWakeWord"` or `"micro"` (for MicroWakeWord models).

Deploy both files to a directory and add it to `wakeWordDirs`:

```nix
services.linux-voice-assistant = {
  wakeModel = "hey_computer";
  wakeWordDirs = [ "/var/lib/linux-voice-assistant/wake-words" ];
};
```

## Bundled wake words

The following wake words are included out of the box:

- `okay_nabu` (default)
- `alexa`
- `hey_jarvis`
- `hey_mycroft`
- `hey_home_assistant`
- `hey_luna`
- `okay_computer`
- `choo_choo_homie`

## Raspberry Pi setup

This works on aarch64 NixOS (Raspberry Pi 3/4/5, Zero 2 W). A minimal config:

```nix
{
  imports = [ inputs.linux-voice-assistant.nixosModules.default ];

  # Enable PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
  };

  services.linux-voice-assistant = {
    enable = true;
    user = "youruser";
    openFirewall = true;
  };
}
```

## Prerequisites

- NixOS with PipeWire (or PulseAudio)
- A microphone and speaker
- Home Assistant with ESPHome integration

## License

This flake is packaging configuration only. The upstream [linux-voice-assistant](https://github.com/OHF-Voice/linux-voice-assistant) is licensed under Apache-2.0.
