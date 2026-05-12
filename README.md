# gpu-watch — A bashingly pretty nvidia-smi monitor

[![Stars](https://img.shields.io/github/stars/eabase/gpu-watch?style=flat-square&color=yellow)](https://github.com/eabase/gpu-watch/stargazers)
[![License](https://img.shields.io/github/license/eabase/gpu-watch?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.1-blue?style=flat-square)](https://github.com/eabase/gpu-watch/releases)
[![Shell](https://img.shields.io/badge/shell-bash-89E051?style=flat-square&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Windows%20(MSYS2)-lightgrey?style=flat-square)](https://www.msys2.org/)
[![NVIDIA](https://img.shields.io/badge/NVIDIA-nvidia--smi-76b900?style=flat-square&logo=nvidia&logoColor=white)](https://developer.nvidia.com/nvidia-system-management-interface)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square)](https://github.com/eabase/gpu-watch/pulls)

```yaml
Author        : eabase
Date          : 2026-05-12
Version       : 1.0.5
Repo          : https://github.com/eabase/gpu-watch
```

---

## Description

A bash-based prettifier wrapper for `nvidia-smi`.
A project vibe-coded using Claude.ai chat.

---

## ✨ Features

- **Color-coded output** for the most relevant GPU metrics (utilization, VRAM, temperature, power)
- **Color legend** included in the display so thresholds are always visible
- **Animated VRAM progress bar** using pure ANSI/Unicode block characters
- **Zero external dependencies** — only native bash and ANSI escape codes
- **Configurable polling interval** (default: 2 seconds)
- Tuned out-of-the-box for the **NVIDIA GeForce RTX 4070 Mobile**

---

## 🖥️patibility

| Environment | Status |
|---|---|
| Linux (bash) | ✅ Supported |
| Windows 11 + MSYS2/MINGW64 | ✅ Supported |
| NVIDIA GeForce RTX 4070 Mobile | ✅ Tested |
| Other NVIDIA GPUs | ⚠️ Requires manual tuning (see below) |

> GPU specs reference: [RTX 4070 Mobile @ TechPowerUp](https://www.techpowerup.com/gpu-specs/geforce-rtx-4070-mobile.c3944)

---

## 🚀 Usage

```bash
./gpu-watch.sh [interval_seconds]   # default interval: 2s
```

**Examples:**
```bash
./gpu-watch.sh        # refresh every 2 seconds
./gpu-watch.sh 1      # refresh every second
./gpu-watch.sh 5      # refresh every 5 seconds
```

---

## :gear: Required GPU Customisation

The color thresholds and limits are tuned for the **RTX 4070 Mobile**. If you have a different card, adjust these values in the script:

| Setting | RTX 4070 Mobile | Action |
|---|---|---|
| Max temperature (throttle point) | `86°C` | Check your GPU specs |
| Max power draw | card TDP | Check your GPU specs |
| VRAM unit | `MiB` | Change to `GiB` for cards with VRAM > 24 GB |

To discover all queryable GPU metrics:

```bash
nvidia-smi --help-query-gpu
nvidia-smi --help-query-gpu | grep --color=always -iE '^".+$|$' -A5

# NOTE:
# - No spaces are allowed between items in the list!
nvidia-smi --query-gpu=timestamp,index,utilization.gpu,memory.used,memory.reserved,memory.total,memory.free,temperature.gpu,power.draw,power.max_limit,c2c.mode,mig.mode.pending,compute_mode,pstate,kmd_version,serial,persistence_mode,addressing_mode,accounting.mode,inforom.img,vbios_version
```

---

## :bar_chart: RAM Progress Bar

Example usage of the *percentBar()* bash function:

```bash
. percent_bar_demo.sh
# The VRAM bottom border is 27 characters wide + 2 edges.
p=47; percentBar  "$p" 27 bar; printf '\U2595\e[0;32m\e[48;5;235m%s\e[0m\U258f%6.2f%%' "$bar" $p; echo
p=47; percentBar2 "$p" 27 bar; printf '\U2595\e[0;32m\e[48;5;235m%s\e[0m\U258f%6.2f%%' "$bar" $p; echo
```

<sub>**NOTE:**  
For more advanced examples of colored *progress-bars* in bash, check out the `percent_bar_demo.sh`,  
and the amazing [bash-script collection](https://f-hauri.ch/vrac/) by [Felix Hauri](http://127.0.0.1/),  
and various *StackOverflow* answers like [this](https://stackoverflow.com/a/79312138/).</sub>

---

## 🌡️ RTX 4070 Mobile — Thermal Notes

- GPU throttling begins at **86°C** (core temperature).
- *Hotspot* temperatures can fluctuate by up to `+/-10%` without worry, as this reading is a "peak momentary" temp.
- *Hotspot* temperatures are not measured by *nvidia-smi*, but by other OS hardware layers.  
  (Check projects like [*LibreHardwareMonitor*](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor), and others.)

---

## 🔗 Similar Projects

| Project | Description |
|---|---|
| [lablup/all-smi](https://github.com/lablup/all-smi) | Super nice Rust replacement for `nvidia-smi` |
| *(yours here)* | Know a bash alternative? Open a PR! |

> No pure-bash alternatives were found at the time of writing.

---

## 🐛 Issues & Contributing

Found a bug or want to add support for your GPU?

- [Open an issue](https://github.com/eabase/gpu-watch/issues)
- [Submit a pull request](https://github.com/eabase/gpu-watch/pulls)
