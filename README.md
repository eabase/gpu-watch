### gpu-watch.sh — A bashingly pretty nvidia-smi monitor

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
- The Max Temperature is `86°C` before the GPU chip is throttling.
- *Hotspot* temperatures can fluctuate by up to `+/-10%` without worry as this reading is "peak momentary" temp.
- *Hotspot* temperatures are not measured by *nvidia-smi*, but by other OS hardware layers.  
   (Check projects like [*LibreHardwareMonitor*](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor), and others.)


For more GPU details that could be added, check:

```bash
nvidia-smi --help-query-gpu
nvidia-smi --help-query-gpu | grep --color=always -iE '^".+$|$' -A5

# NOTE:
# - No spaces are allowed between items in the list!
nvidia-smi --query-gpu=timestamp,index,utilization.gpu,memory.used,memory.reserved,memory.total,memory.free,temperature.gpu,power.draw,power.max_limit,c2c.mode,mig.mode.pending,compute_mode,pstate,kmd_version,serial,persistence_mode,addressing_mode,accounting.mode,inforom.img,vbios_version
```

### The VRAM Progess-bar

Exmaple usage of the *percentBar()* bash function:


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



