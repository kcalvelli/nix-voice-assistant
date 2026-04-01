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

      serviceConfig = {
        ExecStart = let
          args = lib.concatStringsSep " " (
            [ "${pkg}/bin/linux-voice-assistant" ]
            ++ lib.optional (cfg.name != null) "--name '${cfg.name}'"
            ++ lib.optional (cfg.host != null) "--host ${cfg.host}"
            ++ [ "--port ${toString cfg.port}" ]
            ++ lib.optional (cfg.networkInterface != null) "--network-interface ${cfg.networkInterface}"
            ++ lib.optional (cfg.audioInputDevice != null) "--audio-input-device '${cfg.audioInputDevice}'"
            ++ lib.optional (cfg.audioOutputDevice != null) "--audio-output-device '${cfg.audioOutputDevice}'"
            ++ [ "--wake-model ${cfg.wakeModel}" ]
            ++ map (dir: "--wake-word-dir ${dir}") cfg.wakeWordDirs
            ++ [
              "--wakeup-sound ${dataDir}/sounds/wake_word_triggered.flac"
              "--timer-finished-sound ${dataDir}/sounds/timer_finished.flac"
              "--processing-sound ${dataDir}/sounds/processing.wav"
              "--mute-sound ${dataDir}/sounds/mute_switch_on.flac"
              "--unmute-sound ${dataDir}/sounds/mute_switch_off.flac"
            ]
            ++ lib.optional cfg.debug "--debug"
            ++ cfg.extraArgs
          );
        in args;

        User = cfg.user;
        Restart = "on-failure";
        RestartSec = 5;

        # Audio device access
        PrivateDevices = false;
        DevicePolicy = "auto";
      };

      environment = let
        uid = toString (
          if config.users.users ? ${cfg.user}
          then config.users.users.${cfg.user}.uid
          else 1000
        );
      in {
        XDG_RUNTIME_DIR = "/run/user/${uid}";
        PULSE_SERVER = "/run/user/${uid}/pulse/native";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
