#!/usr/bin/env bash
# gpu-watch.sh — Pretty nvidia-smi monitor
#------------------------------------------------------------------------------
# Author	: eabase
# Date		: 2026-05-09
# Version	: 1.0.1
# Repo 		: https://github.com/eabase/gpu-watch
#
#------------------------------------------------------------------------------
#
# Description:
#
#	A bash based prettyfier wrapper for nvidia-smi.
#
# OOB Compatibility:
#
#	- Windows-11 + MSYS/MINGW64 (bash shell)
#	- NVIDIA GeForce RTX 4070 Mobile
#	  https://www.techpowerup.com/gpu-specs/geforce-rtx-4070-mobile.c3944
#
# Features:
#
#	- Shows colors of most relevant GPU variables
#	- Colors are coded with a legend
#	- Legensd settings according to best known specs for the "RTX 4070 Mobile"
#	- Uses only native bash code and ANSI coloring codes. (No tput, awk or other dependecies.)
#
# Required GPU Customisation:
#
# 	Your graphics card or GPU is different from what this script was designed for,
#	so you need to find out and adjust the following:
#
#	- Max Temperature (before GPU throttling)
#	- Max Power draw
#	- Change MiB to GiB for cards with VRAM > 24GB (for better UX)
#
# Usage:
#
#	./gpu-watch.sh <interval_seconds>   (default: 2)
#
# For additional items:
#
#	nvidia-smi --help-query-gpu | grep --color=always -iE '^".+$|$' -A5
#	nvidia-smi --query-gpu=timestamp,index,utilization.gpu,memory.used,\
#		memory.reserved,memory.total,memory.free,temperature.gpu,power.draw,power.max_limit,c2c.mode,\
#		mig.mode.pending,compute_mode,pstate,kmd_version,serial,persistence_mode,addressing_mode,\
#		accounting.mode,inforom.img,vbios_version
#
# Having issues?
#
#	- File bugreport or make a PR to repo
#
# Similar Projects:
#
#	- https://github.com/lablup/all-smi		# Super nice Rust replacement of nvidia-smi
#	- None for bash AFAIK
#
#------------------------------------------------------------------------------


INTERVAL=${1:-2}

# ── ANSI colors ────────────────────────────────────────────────────────────────

RESET="\033[0m"
BOLD="\033[1m"
C_TIME="\033[38;5;240m"
C_IDX="\033[38;5;75m"
C_BLUE="\033[38;5;75m"
C_LGRY="\033[0;37m"		# [38;5;37m --or-- [0;37m  --or-- [1;37m
C_OK="\033[38;5;82m"
C_WARN="\033[38;5;208m"
C_CRIT="\033[38;5;196m"
C_HDR="\033[38;5;245m"
C_SEP="\033[38;5;237m"

# ── Threshold helpers ──────────────────────────────────────────────────────────

vram_color()  { local p=$1
    [ "$p" -ge 95 ] && echo "$C_CRIT" && return
    [ "$p" -gt 80 ] && echo "$C_WARN" && return
    echo "$C_OK"; }
temp_color()  { local t=${1%.*}
    [ "$t" -gt 86 ] && echo "$C_CRIT" && return
    [ "$t" -ge 70 ] && echo "$C_WARN" && return
    echo "$C_OK"; }
power_color() { local w=${1%.*}
    [ "$w" -gt 100 ] && echo "$C_CRIT" && return
    [ "$w" -ge 80  ] && echo "$C_WARN" && return
    echo "$C_OK"; }
gpu_color()   { local g=${1%.*}
    [ "$g" -gt 95 ] && echo "$C_CRIT" && return
    [ "$g" -ge 80 ] && echo "$C_WARN" && return
    echo "$C_BLUE"; }

# ── Column widths ──────────────────────────────────────────────────────────────

W_TIME=11
W_GPU=7
W_UTIL=8
W_VRAM=24
W_TEMP=9
W_PWR=19

# ── Box drawing ────────────────────────────────────────────────────────────────

seg() { printf '─%.0s' $(seq 1 "$1"); }

hline() {
    local L=$1 M=$2 R=$3
    printf "${C_SEP}${L}$(seg $((W_TIME+2)))${M}$(seg $((W_GPU+2)))${M}$(seg $((W_UTIL+2)))${M}$(seg $((W_VRAM+2)))${M}$(seg $((W_TEMP+2)))${M}$(seg $((W_PWR+2)))${R}${RESET}\n"
}

hrow() {
    printf "${C_SEP}│${RESET} ${C_HDR}%-${W_TIME}s${RESET} ${C_SEP}│${RESET} ${C_HDR}%-${W_GPU}s${RESET} ${C_SEP}│${RESET} ${C_HDR}%-${W_UTIL}s${RESET} ${C_SEP}│${RESET} ${C_HDR}%-${W_VRAM}s${RESET} ${C_SEP}│${RESET} ${C_HDR}%-${W_TEMP}s${RESET} ${C_SEP}│${RESET} ${C_HDR}%-${W_PWR}s${RESET} ${C_SEP}│${RESET}\n" \
        "$1" "$2" "$3" "$4" "$5" "$6"
}

hrow_dim() {
    printf "${C_SEP}│${RESET} ${C_SEP}%-${W_TIME}s${RESET} ${C_SEP}│${RESET} ${C_SEP}%-${W_GPU}s${RESET} ${C_SEP}│${RESET} ${C_SEP}%-${W_UTIL}s${RESET} ${C_SEP}│${RESET} ${C_SEP}%-${W_VRAM}s${RESET} ${C_SEP}│${RESET} ${C_SEP}%-${W_TEMP}s${RESET} ${C_SEP}│${RESET} ${C_SEP}%-${W_PWR}s${RESET} ${C_SEP}│${RESET}\n" \
        "$1" "$2" "$3" "$4" "$5" "$6"
}


# ── Static frame: printed once ────────────────────────────────────────────────

print_static_frame() {
    printf "\033c"   # clear screen once (does not reset terminal/colors)
    printf "${C_HDR}  ⬡  GPU Monitor  ${RESET}${C_SEP}—  ${C_HDR}refresh every %ss${RESET}\n\n" "$INTERVAL"
    hline ┌ ┬ ┐
    hrow "TIME"       "GPU#"    "GPU [%]"  "VRAM [MiB]"   "TEMP [°C]" "POWER [W]"
    hrow_dim "[HH:MM:SS]" ""        ""         "used/total (free)" ""       "draw/max"
    hline ├ ┼ ┤
}


# ── Count GPUs once so we know how many data rows to expect ───────────────────

GPU_COUNT=$(nvidia-smi --query-gpu=index --format=csv,noheader 2>/dev/null | wc -l)
[ "$GPU_COUNT" -lt 1 ] && GPU_COUNT=1


# Make a box for the Legend
legend_box() {
    local W=42
    printf "${C_SEP}┌$(seg $((W)))┐${RESET}\n"
    printf "${C_SEP}│${RESET} ${C_HDR}GPU   [%%]   ${C_BLUE}● <80${RESET}    ${C_WARN}● 80–95${RESET}   ${C_CRIT}● >95${RESET}     ${C_SEP}│${RESET}\n"
    printf "${C_SEP}│${RESET} ${C_HDR}VRAM  [%%]   ${C_OK}● <80${RESET}    ${C_WARN}● 80–95${RESET}   ${C_CRIT}● ≥95${RESET}     ${C_SEP}│${RESET}\n"
    printf "${C_SEP}│${RESET} ${C_HDR}TEMP  [°C]  ${C_OK}● <70${RESET}    ${C_WARN}● 70–86${RESET}   ${C_CRIT}● >86${RESET}     ${C_SEP}│${RESET}\n"
    printf "${C_SEP}│${RESET} ${C_HDR}POWER [W]   ${C_OK}● <80${RESET}    ${C_WARN}● 80–100${RESET}  ${C_CRIT}● >100${RESET}    ${C_SEP}│${RESET}\n"
    printf "${C_SEP}└$(seg $((W)))┘${RESET}\n"
}


# ── Print blank placeholder rows + footer + legend (printed once) ─────────────

print_bottom_frame() {
    local i
    for (( i=0; i<GPU_COUNT; i++ )); do
        printf "${C_SEP}│${RESET} %-${W_TIME}s ${C_SEP}│${RESET} %-${W_GPU}s ${C_SEP}│${RESET} %-${W_UTIL}s ${C_SEP}│${RESET} %-${W_VRAM}s ${C_SEP}│${RESET} %-${W_TEMP}s ${C_SEP}│${RESET} %-${W_PWR}s\n" \
            "" "" "" "" "" ""
    done
    hline └ ┴ ┘
    printf "\n"
	legend_box
    printf "\n"
    printf "  ${C_HDR}Press ${C_LGRY}[Ctrl-c]${RESET}${C_HDR} to exit.${RESET}\n"
}

# Lines from cursor (after last header hline) to get back up to row N (0-indexed)
# Layout after hline ├┼┤:
#   row 0 is 1 line down, row 1 is 2 lines down, etc.
# After printing all GPU_COUNT rows + footer + legend lines, we need to go back up.
# Total lines below the ├ separator:
#   GPU_COUNT data rows + 1 (└) + 1 (blank) + 4 legend + 1 (blank) + 1 exit = GPU_COUNT + 8
#LINES_BELOW=$(( GPU_COUNT + 8 ))	# Without legend_box()
LINES_BELOW=$(( GPU_COUNT + 10 ))	# With legend_box()


# ── Overwrite a single data row in place ──────────────────────────────────────

# $1 = 0-indexed row number
update_row() {
    local row_idx=$1
    shift

    local time_only=$1 idx=$2 gpu_util=$3 vram=$4 mem_total=$5 mem_free=$6 temp=$7 pwr=$8 pwr_max=$9

    local vram_pct=0
    [ "$mem_total" -gt 0 ] 2>/dev/null && vram_pct=$(( vram * 100 / mem_total ))

    local C_VRAM; C_VRAM="$(vram_color  "$vram_pct")"
    local C_T;    C_T="$(temp_color     "$temp")"
    local C_P;    C_P="$(power_color    "$pwr")"
    local C_U;    C_U="$(gpu_color      "$gpu_util")"

    local p_time; p_time=$(printf "%-${W_TIME}s"  "$time_only")
    local p_idx;  p_idx=$(printf  "%${W_GPU}s"    "$idx")
    local p_util; p_util=$(printf "%-${W_UTIL}s"  "${gpu_util} %")
    local p_temp; p_temp=$(printf "%-${W_TEMP}s"  "${temp} °C")
    local p_vram_used; p_vram_used=$(printf "%5d" "$vram")
    local p_vram_tot;  p_vram_tot=$(printf  "%-5d" "$mem_total")
    local p_pwr_draw;  p_pwr_draw=$(printf "%6s" "$pwr")
    local p_pwr_max;   p_pwr_max=$(printf  "%-6s" "$pwr_max")

    # Move cursor up from bottom of printed block to the target row
    # We are currently sitting after the last line printed; move up enough lines.
    local lines_up=$(( LINES_BELOW - row_idx ))
    printf "\033[%dA\r" "$lines_up"

    # Overwrite the row
    # VRAM visible: "%5d / %5d (%5d)" = 5+3+5+2+5+1 = 21 + leading space = 22 = W_VRAM ✓
    # POWER visible: "%6s / %-10s" = 6+3+10 = 19 = W_PWR ✓

    printf "${C_SEP}│${RESET}"
    printf " ${C_TIME}%s${RESET} ${C_SEP}│${RESET}" "$p_time"
    printf " ${C_IDX}%s${RESET} ${C_SEP}│${RESET}"  "$p_idx"
    printf " ${C_U}%s${RESET} ${C_SEP}│${RESET}"    "$p_util"
    printf " ${C_VRAM}%5d${RESET} / ${C_BLUE}%5d${RESET} ${C_SEP}(${RESET}${C_HDR}%-4d${RESET}${C_SEP})${RESET}     ${C_SEP}│${RESET}" "$vram" "$mem_total" "$mem_free"
    printf " ${C_T}%s °C    ${RESET} ${C_SEP}│${RESET}"  "$temp"
    printf " ${C_P}%6s${RESET} / ${C_BLUE}%-10s${RESET} ${C_SEP}│${RESET}" "$pwr" "$pwr_max"

    # Move cursor back down to bottom
    printf "\033[%dB\r" "$lines_up"
}


# ── Poll: read nvidia-smi, update each row in place ───────────────────────────

poll() {
    local row_idx=0
    while IFS=',' read -r ts idx gpu_util mem_used mem_res mem_total mem_free temp pwr pwr_max; do
        ts=$(echo "$ts"               | xargs)
        idx=$(echo "$idx"             | xargs)
        gpu_util=$(echo "$gpu_util"   | xargs)
        mem_used=$(echo "$mem_used"   | xargs)
        mem_res=$(echo "$mem_res"     | xargs)
        mem_free=$(echo "$mem_free"   | xargs)
        mem_total=$(echo "$mem_total" | xargs)
        temp=$(echo "$temp"           | xargs)
        pwr=$(echo "$pwr"             | xargs)
        pwr_max=$(echo "$pwr_max"     | xargs)

        local time_only; time_only=$(echo "$ts" | grep -oP '\d{2}:\d{2}:\d{2}')
        local vram=$(( mem_used + mem_res ))

        update_row "$row_idx" "$time_only" "$idx" "$gpu_util" "$vram" "$mem_total" "$mem_free" "$temp" "$pwr" "$pwr_max"
        row_idx=$(( row_idx + 1 ))
    done < <(nvidia-smi \
        --query-gpu=timestamp,index,utilization.gpu,memory.used,memory.reserved,memory.total,memory.free,temperature.gpu,power.draw,power.max_limit \
        --format=csv,noheader,nounits 2>/dev/null)
}

# ── Init ───────────────────────────────────────────────────────────────────────

trap 'printf "\033[0m\n"; exit 0' INT TERM

print_static_frame
print_bottom_frame


# ── Main loop ──────────────────────────────────────────────────────────────────

while true; do
    poll
    sleep "$INTERVAL"
done

#------------------------------------------------------------------------------
#  END
#------------------------------------------------------------------------------
