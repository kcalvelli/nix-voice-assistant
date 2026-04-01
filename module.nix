{ self }:

{ config, lib, pkgs, ... }:

let
  cfg = config.services.linux-voice-assistant;
  pkg = self.packages.${pkgs.stdenv.hostPlatform.system}.linux-voice-assistant;
  dataDir = "${pkg}/share/linux-voice-assistant";
in
{
  options.services.linux-voice-assistant = {
    enable = lib.mkEnableOption "linux-voice-assistant, a voice satellite for Home Assistant";

    user = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "User to run the service as. Must have access to the PipeWire/PulseAudio socket.";
    };

    name = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Friendly name for the device (auto-generated from MAC if null).";
    };

    host = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "IP address to bind to (auto-detected if null).";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 6053;
      description = "Port for the ESPHome API.";
    };

    networkInterface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Network interface for IP/MAC detection (auto-detected if null).";
    };

    audioInputDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Audio input device name or index (see --list-input-devices).";
    };

    audioOutputDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Audio output device for mpv (see --list-output-devices).";
    };

    wakeModel = lib.mkOption {
      type = lib.types.str;
      default = "okay_nabu";
      description = "Wake word model name to use.";
    };

    wakeWordDirs = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Additional directories containing wake word models (.tflite + .json).";
    };

    debug = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable debug logging.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the ESPHome API port in the firewall.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra command-line arguments to pass to linux-voice-assistant.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.linux-voice-assistant = {
      description = "Linux Voice Assistant for Home Assistant";
      after = [ "network-online.target" "pipewire.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.iproute2 pkgs.which ];

      # Use script instead of ExecStart so we can resolve UID at runtime
      # (NixOS config may have uid=null when auto-assigned)
      script = let
        args = lib.concatStringsSep " " (
          [ "'${pkg}/bin/linux-voice-assistant'" ]
          ++ lib.optionals (cfg.name != null) [ "--name" "'${cfg.name}'" ]
          ++ lib.optionals (cfg.host != null) [ "--host" cfg.host ]
          ++ [ "--port" (toString cfg.port) ]
          ++ lib.optionals (cfg.networkInterface != null) [ "--network-interface" cfg.networkInterface ]
          ++ lib.optionals (cfg.audioInputDevice != null) [ "--audio-input-device" "'${cfg.audioInputDevice}'" ]
          ++ lib.optionals (cfg.audioOutputDevice != null) [ "--audio-output-device" "'${cfg.audioOutputDevice}'" ]
          ++ [ "--wake-model" cfg.wakeModel ]
          ++ lib.concatMap (dir: [ "--wake-word-dir" "'${toString dir}'" ]) cfg.wakeWordDirs
          ++ [
            "--download-dir" "'/var/lib/linux-voice-assistant/downloads'"
            "--preferences-file" "'/var/lib/linux-voice-assistant/preferences.json'"
            "--wakeup-sound" "'${dataDir}/sounds/wake_word_triggered.flac'"
            "--timer-finished-sound" "'${dataDir}/sounds/timer_finished.flac'"
            "--processing-sound" "'${dataDir}/sounds/processing.wav'"
            "--mute-sound" "'${dataDir}/sounds/mute_switch_on.flac'"
            "--unmute-sound" "'${dataDir}/sounds/mute_switch_off.flac'"
          ]
          ++ lib.optional cfg.debug "--debug"
          ++ cfg.extraArgs
        );
      in ''
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"
        export PULSE_SERVER="$XDG_RUNTIME_DIR/pulse/native"
        exec ${args}
      '';

      serviceConfig = {
        User = cfg.user;
        Restart = "on-failure";
        RestartSec = 5;

        # Audio device access
        PrivateDevices = false;
        DevicePolicy = "auto";
      };
    };

    # Writable state directory for downloads and preferences
    systemd.tmpfiles.rules = [
      "d /var/lib/linux-voice-assistant 0755 ${cfg.user} users -"
      "d /var/lib/linux-voice-assistant/downloads 0755 ${cfg.user} users -"
    ];

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
