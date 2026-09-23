{ config, lib, pkgs, ... }:

# OBS Studio for live camera streaming (Twitch + YouTube simultaneously).
#
# Camera sources only -- this is not a game-capture setup, so there is no
# obs-vkcapture and no PRIME/NVENC involvement. Encoding is x264 on the CPU
# (the 7700HQ has four otherwise-idle cores here), with VAAPI on the HD 630
# iGPU as the thermal fallback. The VAAPI drivers (and a note on why there is
# no global LIBVA_DRIVER_NAME) live in import-08-gpu.nix.
#
# The GTX 1060 is deliberately not involved: Pascal NVENC is worse than x264
# on camera content (skin tones, shadow noise, slow motion are exactly where
# older hardware encoders fall apart) and there is no game load to offload.
{
  # OBS must be installed through this module (or pkgs.wrapOBS) rather than as
  # a bare pkgs.obs-studio in systemPackages: plugins are linked into the
  # wrapper at build time and a bare OBS will not see any of them.
  programs.obs-studio = {
    enable = true;

    # Sets up v4l2loopback so OBS output appears as a webcam to other apps.
    # Not needed to push straight to Twitch/YouTube -- turn on only if OBS
    # output has to feed a video call.
    enableVirtualCamera = false;

    plugins = with pkgs.obs-studio-plugins; [
      # IP/RTSP cameras. Better latency control than the built-in ffmpeg
      # Media Source path.
      obs-gstreamer

      # The simultaneous Twitch + YouTube push (Tools -> Multiple Output).
      obs-multi-rtmp

      # Phone-as-camera over USB/WiFi, presented as a V4L2 device.
      droidcam-obs

      # The feeds run unattended, so scene cuts have to happen on a timer or
      # on a condition rather than by hand.
      advanced-scene-switcher

      # obs-pipewire-audio-capture -- NOT needed on this channel. OBS 32.1.2
      # here is built with -DENABLE_PIPEWIRE=TRUE, which already provides
      # "Application Audio Capture (PipeWire)" natively in the source list.
      #obs-pipewire-audio-capture
    ];
  };

  environment.systemPackages = with pkgs; [
    # `vainfo` -- verification that the VAAPI encode fallback is actually
    # available (look for VAEntrypointEncSlice under an H264 profile).
    libva-utils

    # `v4l2-ctl` -- enumerate cameras and script exposure/white-balance so a
    # known-good setup can be pinned at startup.
    v4l-utils

    # GUI for the same controls. Auto-exposure hunting is the most common
    # cause of amateurish-looking camera streams; both of these exist to pin
    # exposure and white balance to manual.
    cameractrls

    # `lsusb -t` -- maps ports to USB controllers. This laptop has a single
    # USB 3.0 controller shared across its ports, so several 1080p webcams
    # can saturate it (symptom: one feed goes black or refuses to open).
    # Cameras must also negotiate MJPEG, not YUYV -- 1080p30 YUYV is roughly
    # 1.5 Gbps per camera and simply will not fit.
    usbutils

    # `sensors` -- sustained x264 on a 2017 chassis is a thermal question,
    # and this is how you tell throttling from a software problem.
    lm_sensors
  ];

  # --- Unattended operation ----------------------------------------------
  # The stream runs on its own, so nothing may suspend the machine or blank
  # the output mid-session.
  services.logind.settings.Login = {
    # Never suspend on idle.
    IdleAction = "ignore";

    # Keep running with the lid shut. NOTE: a closed lid means noticeably
    # worse airflow on this chassis -- prefer to leave it open while
    # streaming if the physical setup allows it.
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  # GNOME session: stop the shell blanking the screen or auto-suspending.
  # These are defaults, not locks, so they can still be changed in Settings.
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/desktop/session".idle-delay = lib.gvariant.mkUint32 0;
        "org/gnome/desktop/screensaver".lock-enabled = false;
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
          sleep-inactive-battery-type = "nothing";
        };
      };
    }
  ];

  # Hyprland session: services.hypridle.enable is true (pulled in by
  # programs.hyprlock.enable in import-05-desktop-hyprland.nix) and its unit
  # is wantedBy graphical-session.target -- which GNOME activates too, so it
  # is NOT scoped to the Hyprland session.
  #
  # It is harmless today only because the nixpkgs module ships no config
  # (it exposes just `enable` and `package`), there is no /etc fallback, and
  # ~/.config/hypr has never been populated -- so hypridle aborts at session
  # start and hypridle.service sits in `failed`. Nothing it would do can
  # suspend the machine.
  #
  # THE CATCH: running hypr-quickshell-config/copyconfig.sh installs
  # hypridle.conf, at which point hypridle starts working -- under GNOME as
  # well -- and its listeners (lock 5 min, DPMS off 5.5 min, SUSPEND AT
  # 30 MIN) go live and would kill an unattended stream. If that script is
  # ever run, drop or lengthen the suspend listener in
  # ~/.config/hypr/hypridle.conf.
}
