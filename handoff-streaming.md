# Handoff: OBS camera streaming on `helios`

**Status as of 2026-09-23: config written, `nixos-rebuild switch` applied and verified.**
(Generation 5, `29aaanv66sl7...`; matches `/nix/var/nix/profiles/system`;
`dry-build` builds nothing new; no failed units, system or user.)
Nothing is broken and nothing is half-done. What remains is physical (cameras,
thermal paste) and runtime OBS setup, not Nix work.

This file supersedes the original planning handoff. Several claims in that
document were wrong for this specific machine — see **Corrections** below
before acting on anything from it.

---

## 1. What is in the config now

| File | Change |
|---|---|
| `import-09-streaming.nix` | **New.** All OBS/streaming config. |
| `configuration.nix` | One line: `./import-09-streaming.nix` added to `imports`. |
| `import-08-gpu.nix` | **Comments only — no functional change.** Documents why there is deliberately no global `LIBVA_DRIVER_NAME`. |

`import-09-streaming.nix` contains:

- `programs.obs-studio.enable` with 4 plugins (`obs-gstreamer`, `obs-multi-rtmp`,
  `droidcam-obs`, `advanced-scene-switcher`).
- `enableVirtualCamera = false` — not needed for a straight RTMP push. Flip to
  `true` only if OBS output must appear as a webcam to other apps.
- `systemPackages`: `libva-utils`, `v4l-utils`, `cameractrls`, `usbutils`, `lm_sensors`.
- `services.logind.settings.Login` — `IdleAction=ignore` + all three
  `HandleLidSwitch*=ignore`, for unattended operation.
- `programs.dconf.profiles.user.databases` — GNOME idle/blank/auto-suspend off
  (defaults, not locks; still changeable in Settings).

**OBS must stay installed via `programs.obs-studio`.** A bare `pkgs.obs-studio`
in `systemPackages` produces an OBS that cannot see any plugins, because
plugins are linked into the wrapper at build time. Never have both.

---

## 2. Verified on the running system (not predicted)

Machine: NixOS **26.05**.10402.1e8bc658fc98 (Yarara), channel `nixos-26.05`.
Channel-based, **not a flake**.

**OBS 32.1.2**, all four plugins live in `/run/current-system/sw/lib/obs-plugins/`:
`obs-gstreamer.so`, `obs-multi-rtmp.so`, `droidcam-obs.so`, `advanced-scene-switcher.so`.

**Browser source works.** `libcef.so`, `obs-browser.so`, `obs-browser-page`
all present; OBS was built `-DENABLE_BROWSER:BOOL=TRUE` with `cef-binary-6533`.
→ Overlays/alerts are fine. **The Flatpak escape hatch is NOT needed.**

**VAAPI encode fallback is available.** `vainfo` → Intel iHD driver 26.1.6,
VA-API 1.23:
- `VAProfileH264Main/High/ConstrainedBaseline : VAEntrypointEncSlice`
- same three also expose `VAEntrypointEncSliceLP` (fixed-function low-power
  VDEnc — even cheaper than normal VAAPI encode, slight quality cost; surfaces
  as a low-power toggle in OBS's VAAPI encoder)
- HEVC Main/Main10 encode also present (irrelevant for RTMP)

**Unattended settings live.**
`busctl get-property org.freedesktop.login1 ... IdleAction` → `s "ignore"`.

**Cameras today:** only the built-in `HD WebCam` →
`/dev/video0` (capture), `/dev/video1` (metadata), `/dev/media0`.
Max **1280x720**, MJPG and YUYV. No 1080p from this one.

**USB topology** (`lsusb -t`):
```
Bus 001: xhci_hcd/16p, 480M   <- USB 2.0. Built-in webcam is here (Port 009), bluetooth Port 007
Bus 002: xhci_hcd/8p,  5000M  <- USB 3.0, currently EMPTY
```

**Idle thermals:** package ~50 °C, cores 48–49 °C, `high`/`crit` = 100 °C.
That is the baseline to compare against under streaming load.

---

## 3. Corrections to the original handoff — read before reusing it

**3.1 — "Do not install the NVIDIA driver" is moot.**
The driver was *already* configured in `import-08-gpu.nix` (`legacy_580` pin,
PRIME offload) long before this work, and `CLAUDE.md` says explicitly not to
touch that pin. The original doc was written without knowing this. **Decision
taken: leave it alone.** OBS renders and encodes on the Intel HD 630 regardless;
the 1060 just idles. Ripping it out is a whole-system change, well beyond OBS
scope, and would break `nvidia-offload` for other things (`moonlight-qt`).

**3.2 — Do NOT set `environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD"`.**
The original doc asked for this. It is wrong on *this* machine. Measured:

- Auto-detect already resolves correctly, with no env var at all:
  `vainfo --display drm --device /dev/dri/renderD128` → iHD. libva's detection
  is **per-device**; there was never a wrong pick to prevent.
- Forcing iHD onto the NVIDIA node fails hard:
  `LIBVA_DRIVER_NAME=iHD vainfo --device /dev/dri/renderD129`
  → `libva error: ... iHD_drv_video.so init failed` / `va_openDriver() returns 18`.
- `sessionVariables` is global, so that pin would break VAAPI decode for
  anything on `renderD129` — concretely `moonlight-qt` under `nvidia-offload`.

Render nodes here: `renderD128` = Intel (`0x8086`), `renderD129` = NVIDIA (`0x10de`).
If one app ever needs pinning, do it per-process: `LIBVA_DRIVER_NAME=iHD obs`.
Use `i965` (`intel-vaapi-driver`, already installed) if iHD ever misbehaves.

**3.3 — `obs-pipewire-audio-capture` was deliberately omitted.**
OBS 32.1.2 here is built `-DENABLE_PIPEWIRE:BOOL=TRUE` and already provides
**"Application Audio Capture (PipeWire)"** natively in the source list. The
plugin is redundant. Left commented in the module with this reason.

**3.4 — Things that were already correct and were NOT duplicated.**
PipeWire (`import-04-audio.nix`: alsa + pulse + rtkit, pulseaudio off);
`pep` already in `video` and `render` (`import-08-gpu.nix`);
`hardware.graphics` already carried `intel-media-driver` + `intel-vaapi-driver`.
Option name is `hardware.graphics` on 26.05 (`hardware.opengl` is pre-24.11).

**3.5 — The CPU is an i7-7700HQ.** Kaby Lake, 4c/8t. There is no "7700HX";
Intel's mobile HX line started at 12th gen.

---

## 4. The one live trap: `hypridle`

`services.hypridle.enable` is **true** — pulled in by `programs.hyprlock.enable`
in `import-05-desktop-hyprland.nix`. Its unit is
`wantedBy = [ "graphical-session.target" ]`, which **GNOME activates too**. It
is *not* scoped to the Hyprland session.

It is harmless *right now* only by accident: the nixpkgs module ships no config
(it exposes only `enable` and `package`), there is no `/etc` fallback, and
`~/.config/hypr` has never been populated — so hypridle aborts at session start
(observed: `status=6/ABRT`). The unit currently sits `inactive (dead)` --
the rebuild reset its start-limit counter, so it no longer shows `failed`.
Either way it is not running and cannot suspend anything.

**The catch:** running `hypr-quickshell-config/copyconfig.sh` installs
`hypridle.conf`, at which point hypridle starts working **under GNOME as well**,
and its listeners go live:

```
300s  -> loginctl lock-session
330s  -> dpms off
1800s -> systemctl suspend     <-- would kill an unattended stream
```

If that script is ever run, drop or lengthen the suspend listener in
`~/.config/hypr/hypridle.conf`. The logind/dconf settings in
`import-09-streaming.nix` cannot reach it — it is a dotfile, and this repo does
not install dotfiles.

---

## 5. What is left to do

**Nix side: nothing pending.** Everything above is applied.

Only if requirements change:
- Multi-camera phones → `droidcam-obs` already installed, nothing to add.
- OBS output needed as a webcam elsewhere → `enableVirtualCamera = true`.
- `obs-vaapi` plugin exists on this channel but is **not** needed; OBS's
  built-in FFmpeg VAAPI encoder covers the fallback.
- OBS's *native* QuickSync encoder (built in, `-DENABLE_QSV11=TRUE` + `libvpl`)
  will likely not work on Kaby Lake without `intel-media-sdk` (Gen9 legacy MSDK
  runtime; `vpl-gpu-rt` is Gen12+). Both are packaged. **Not added** — the VAAPI
  path already covers the fallback. Only chase this if VAAPI proves insufficient.

**Physical / runtime side:**
1. Attach the real cameras. Only the 720p built-in exists today.
2. Put external 1080p webcams on **Bus 002** (the 8-port 5000M controller).
   Bus 001 is USB 2.0 at 480M and will not carry 1080p usefully.
3. Verify each camera negotiates **MJPEG**:
   `v4l2-ctl -d /dev/videoN --list-formats-ext`
   1080p30 **YUYV is ~1.5 Gbps per camera** and will fail outright. Symptom of
   over-subscribing the controller: one feed goes black or refuses to open.
4. Clean fans / repaste. 2017 chassis, nine-year-old paste. This matters more
   than any software tuning. `linuwu-sense` is an out-of-tree module exposing
   Predator fan control if curves become necessary — not currently installed.

---

## 6. OBS runtime settings — NOT declarative, do by hand

- **Encoder: x264, `veryfast`, CBR 6000 kbps, keyframe interval 2, 1080p60.**
  ~40% CPU on this chip with no other load. Chosen over Pascal NVENC
  deliberately: on *camera* content (skin tones, shadow noise, slow gradual
  motion) older hardware encoders degrade exactly where it shows most.
- **Fallback if sustained temps are a problem:** switch to VAAPI on the HD 630
  (confirmed available, §2). Try `EncSliceLP`/low-power if you need more headroom.
- **Set exposure and white balance to MANUAL** on every camera. Auto-exposure
  hunting is the single most common cause of amateurish-looking camera streams,
  and it is worse on Linux where vendor tuning is absent.
  `cameractrls` (GUI) or `v4l2-ctl` (scriptable — use it to pin a known-good
  setup at startup). Both installed.
- **A camera used in multiple scenes must be added as a reference to the same
  source**, never duplicated. Duplicating opens the V4L2 device twice and the
  second instance fails.
- **Twitch + YouTube simultaneously doubles upload.** ~8–10 Mbps stable per
  6000 kbps stream → **~16–20 Mbps for both.** Wired strongly preferred; Wi-Fi
  jitter drops more frames than any hardware issue here.
- Multi-RTMP lives under **Tools → Multiple Output**.

---

## 7. Commands

```bash
scripts/nurse.sh                     # nixos-rebuild switch
nixos-rebuild dry-build              # cheap eval check, changes nothing
nixos-rebuild switch --rollback      # undo last generation

vainfo | grep -i encslice            # VAAPI encode entrypoints
v4l2-ctl --list-devices              # enumerate cameras
v4l2-ctl -d /dev/video0 --list-formats-ext   # MJPEG vs YUYV
lsusb -t                             # map cameras to USB controllers
sensors                              # thermals; idle baseline ~50 C package
systemctl --user status hypridle     # expect: inactive/dead or failed -- NOT running (see section 4)
```

Run rebuilds as root from `/etc/nixos`.
