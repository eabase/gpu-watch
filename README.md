### gpu-watch.sh — A bash pretty nvidia-smi monitor

```yaml
Author        : eabase
Date          : 2026-05-09
Version       : 1.0.1
Repo          : https://github.com/eabase/gpu-watch
```

---

Description:

      A bash based prettyfier wrapper for nvidia-smi.
      A project vibe-coded using Claud.AI chat.

OOB Compatibility:

      - Windows-11 + MSYS/MINGW64 (bash shell)
      - NVIDIA GeForce RTX 4070 Mobile
        https://www.techpowerup.com/gpu-specs/geforce-rtx-4070-mobile.c3944

Features:

      - Shows colors of most relevant GPU variables
      - Colors are coded with a legend
      - Legensd settings according to best known specs for the "RTX 4070 Mobile"
      - Uses only native bash code and ANSI coloring codes. (No tput, awk or other dependecies.)

Required GPU Customisation:

      Your graphics card or GPU is different from what this script was designed for,
      so you need to find out and adjust the following:

      - Max Temperature (before GPU throttling)
      - Max Power draw
      - Change MiB to GiB for cards with VRAM > 24GB (for better UX)

Usage:

      ./gpu-watch.sh <interval_seconds>   (default: 2)

Having issues?

      - File bugreport or make a PR to repo

Similar Projects:

      - https://github.com/lablup/all-smi             # Super nice Rust replacement of nvidia-smi
      - None for bash AFAIK

---

#### NOTES

For the `RTX 4070 Mobile`:
- 86°C prior to the chip throttling
- Hotspot temps can fluctuate by up to +/-10% without worry as this reading is "peak momentary" temp 

For more details, that could be added, chech:

```bash
nvidia-smi --help-query-gpu
nvidia-smi --help-query-gpu | grep --color=always -iE '^".+$|$' -A5

# NOTE: 
# No space is allowed between items in list
nvidia-smi --query-gpu=timestamp,index,utilization.gpu,memory.used,memory.reserved,memory.total,memory.free,temperature.gpu,power.draw,power.max_limit,c2c.mode,mig.mode.pending,compute_mode,pstate,kmd_version,serial,persistence_mode,addressing_mode,accounting.mode,inforom.img,vbios_version
```


