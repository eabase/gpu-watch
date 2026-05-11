#!/usr/bin/env bash
# gpu-watch.sh — A prettyfied nvidia-smi GPU monitor in bash
#------------------------------------------------------------------------------
# Author	: eabase
# Date		: 2026-05-10
# Version	: 1.0.4
# Repo 		: https://github.com/eabase/gpu-watch
#
#------------------------------------------------------------------------------
#
# Description:
#
#	A minimalistic bash-based colored prettyfier wrapper for nvidia-smi and CLI use.
#
# OOB Compatibility:
#
#	- Windows-11 + MSYS/MINGW64 (bash shell)
#	- NVIDIA GeForce RTX 4070 Mobile [1]
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
#	so you need to manuall find-out and adjust the following:
#
#	- Max Temperature (before GPU throttling)
#	- Max Power draw
#	- Change MiB to GiB for cards with VRAM > 24GB (for better UX)
#
# Usage:
#
#	./gpu-watch.sh <interval_seconds>   (default: 2)
#
# Useful nvidia-smi commands:
#
#   nvidia-smi -q -d CLOCK
#   nvidia-smi -q -d POWER
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
#	- File bugreport and/or make a PR to repo
#
# Similar Projects:
#
#	- None for Bash AFAIK
#	- https://github.com/lablup/all-smi		# Super nice Rust based nvtop-styled replacement of nvidia-smi
#
#------------------------------------------------------------------------------
# NOTES
#
#   The Bash shellcheck testing have issues with this script as:
#   - it depends on using inline variables within printf()
#   - it uses multiple commands on one line, while shellcheck is only able to check one command at the time.
#   - Some variables are placeholders for ToDo items.
#
# ToDo:
#   - [ ] Move this list into repo issue or README file.
#   - [ ] Remove all shellcheck statements, as it is not useful/compatible with this script.
#   - [x] Separate out BAR_COLOR and use only one percentBar() line in print_vram_bar()
#   - [-] Add automatic detection of GPU Max power level in get_card_powers() - Already obtained in poll()!
#   - [x] Add automatic detection of GPU Max clock rate in get_card_powers()
#   - [ ] Add column for current SM clock rate.
#   - [-] Fix colors of data line for newly added (pstate) column items
#   - [ ] Move VRAM "progress" bar into VRAM cell (need 2 lines) using a "thin line" UTF-8 character (`\U258?`)
#
# References:
#
#   [1] https://www.techpowerup.com/gpu-specs/geforce-rtx-4070-mobile.c3944
#   [2] 
#   [3] https://www.shellcheck.net/
#   [4] https://github.com/koalaman/shellcheck
#   [5] 
#   [6] 
#
#------------------------------------------------------------------------------

# ── Init / Setup ─────────────────────────────────────────────────────────────

DEBUG=0

# Update interval as option.  Default: 2 seconds. 
# But this is not accurate, due to bash script latency!
INTERVAL=${1:-2}

# ── ANSI colors ────────────────────────────────────────────────────────────────

RESET="\033[0m"             # 
#BOLD="\033[1m"              # 
C_TIME="\033[38;5;240m"     # 
C_IDX="\033[38;5;75m"       # BrightBlue ?
C_BLUE="\033[38;5;75m"      # BrightBlue ?
C_LGRY="\033[0;37m"		    # [38;5;37m --or-- [0;37m  --or-- [1;37m
C_OK="\033[38;5;82m"        # 
C_WARN="\033[38;5;208m"     # 
C_CRIT="\033[38;5;196m"     # 
C_HDR="\033[38;5;245m"      # 
C_SEP="\033[38;5;237m"      # 

# ── Helper Functions (Progress Bar) ────────────────────────────────────────────

#── Shellcheck Disabled ──────────────────────────────────────
# shellcheck disable=SC2059     # Using variables in the printf
# shellcheck disable=SC2034     # ToDo Use Unused variables 

#── ANSI Color Codes ──────────────────────────────────────

# Here we use 'ESC=\e' for readability, but if this fails on your OS, use: '\033' (Oct) or '\x1b' (Hex).
VP_RED='\e[0;31m'       # Red
VP_GRN='\e[0;32m'       # Green
VP_ORA='\e[0;33m'       # Orange
#VP_LGR='\e[0;37m'       # Light Gray
#VP_DGR="\e[0;37m"       # Dark Gray

#── Global Variables ──────────────────────────────────────

# VRAM percentage set (exported) in update_row() and used in update_vram_bar()
#let VRAMP=0	
((VRAMP=0))
((MAX_POWER=0))
((MAX_SM_CLOCK=0))

#── Helper Functions ──────────────────────────────────────

get_card_powers () {
    # Manual Detection of Graphics card power settings
    #────────────────────────────────────────────────────
    # NOTE
    # - For an "RTX 4070 Laptop", we have:
    #       MAX_POWER       :  140 [W] 
    #       MAX_SM_CLOCK    : 3105 [MHz]
    #
    # - MAX_POWER    is already obtained by 'power.max_limit'
    # - MAX_SM_CLOCK is already obtained by 'clocks.max.sm'
    # 
    #   nvidia-smi -q -d POWER
    #   nvidia-smi -q -d CLOCK
    #       Provides: [Graphics,SM,Memory,Video]
    #       - SM      : The Streaming Multiprocessor clock (SM) is the most important for compute-heavy workloads.
    #       - Memory  : The GPU DRAM (GDDR/HBM) clock determines memory bandwidth and memory bus width.
    #────────────────────────────────────────────────────
    MAX_POWER=$(nvidia-smi -q -d POWER | grep "Max Power Limit" -m 1 | awk -F " " '{print int($5)}')
    MAX_SM_CLOCK=$(nvidia-smi -q -d CLOCK | grep -E "Max Clocks" -A2 | tail -1 |  awk -F " " '{print int($3)}')
    #[ -z "$MAX_POWER" ] && MAX_POWER=140            # Set to a known default in case above fails
    #[ -z "$MAX_SM_CLOCK" ] && MAX_SM_CLOCK=3105     # Set to a known default in case above fails
}

percentBar ()  {
    local prct totlen=$((8*$2)) lastchar barstring blankstring;
    printf -v prct %.2f "$1"
    ((prct=10#${prct/.}*totlen/10000, prct%8)) &&
        printf -v lastchar '\\U258%X' $(( 16 - prct%8 )) ||
            lastchar=''
    printf -v barstring '%*s' $((prct/8)) ''
    printf -v barstring '%b' "${barstring// /\\U2588}$lastchar"
    printf -v blankstring '%*s' $(((totlen-prct)/8)) ''
    printf -v "$3" '%s%s' "$barstring" "$blankstring"
}


# Usage:  print_vram_bar <percentage>
print_vram_bar () {
	# The legend box is 45 characters wide:
    #BARWIDTH=$((COLUMNS-7))
    local p=$1 BARWIDTH=$((42))
    if   [ "$p" -gt 90 ]; then color="$VP_RED"
    elif [ "$p" -gt 70 ]; then color="$VP_ORA"
    else                       color="$VP_GRN"
    fi
    # shellcheck disable=SC2154     # unassigned variable
	# As bar "limits" we use the "right-bar" (\u2595) and "left-bar" (\u258f) UTF-8 characters.
    percentBar "$p" $BARWIDTH bar; printf '\r\U2595'"$color"'\e[48;5;235m%s\e[0m\U258f%4.0f%% VRAM' "$bar" "$p"
}

# Add a dedicated function to overwrite just the bar line:
update_vram_bar() {
    local lines_up=$(( LINES_BELOW - GPU_COUNT - 2 ))  # 2 = footer line + blank line
    printf "\033[%dA\r" "$lines_up"
    print_vram_bar "$VRAMP"
    printf "\033[%dB\r" "$lines_up"
}


# ── Threshold helpers ──────────────────────────────────────────────────────────

vram_color()  { local p=$1
    [ "$p" -ge 95 ] && echo "$C_CRIT" && return     # severly affects concurrent use of graphics & AI TPS values
    [ "$p" -gt 80 ] && echo "$C_WARN" && return     # normal - multi-use possible
    echo "$C_OK"; }
temp_color()  { local t=${1%.*}
    [ "$t" -gt 86 ] && echo "$C_CRIT" && return     # This is the Tc for triggering GPU throttling
    [ "$t" -ge 70 ] && echo "$C_WARN" && return     # normal
    echo "$C_OK"; }
power_color() { local w=${1%.*}
    [ "$w" -gt 100 ] && echo "$C_CRIT" && return    # ToDo: automatic detection
    [ "$w" -ge 80  ] && echo "$C_WARN" && return    # normal
    echo "$C_OK"; }
gpu_color()   { local g=${1%.*}
    [ "$g" -gt 95 ] && echo "$C_CRIT" && return     # Who/what cares?
    [ "$g" -ge 80 ] && echo "$C_WARN" && return     # Who/what cares?
    echo "$C_BLUE"; }

# ── Column widths ──────────────────────────────────────────────────────────────

W_TIME=10   # 11
W_GPU=4     # 7
W_PSTATE=5  # 8
W_UTIL=7    # 8
W_VRAM=24   # 24    fails on 22
W_TEMP=9
W_PWR=19    # 19   fails on 17

# ── Box drawing ────────────────────────────────────────────────────────────────

seg() { printf '─%.0s' $(seq 1 "$1"); }

# shellcheck disable=SC2059
hline() {
    local L=$1 M=$2 R=$3
    printf "${C_SEP}${L}$(seg $((W_TIME+2)))${M}$(seg $((W_GPU+2)))${M}$(seg $((W_PSTATE+2)))${M}$(seg $((W_UTIL+2)))${M}$(seg $((W_VRAM+2)))${M}$(seg $((W_TEMP+2)))${M}$(seg $((W_PWR+2)))${R}${RESET}\n"
}

hrow() {
    printf "${C_SEP}│${RESET} ${C_HDR}%-${W_TIME}s${RESET} ${C_SEP}│${RESET} ${C_HDR}%-${W_GPU}s${RESET} ${C_SEP}│${RESET} ${C_HDR}%-${W_PSTATE}s${RESET} ${C_SEP}│${RESET} ${C_HDR}%-${W_UTIL}s${RESET} ${C_SEP}│${RESET} ${C_HDR}%-${W_VRAM}s${RESET} ${C_SEP}│${RESET} ${C_HDR}%-${W_TEMP}s${RESET} ${C_SEP}│${RESET} ${C_HDR}%-${W_PWR}s${RESET} ${C_SEP}│${RESET}\n" \
        "$1" "$2" "$3" "$4" "$5" "$6" "$7"
}

hrow_dim() {
    printf "${C_SEP}│${RESET} ${C_SEP}%-${W_TIME}s${RESET} ${C_SEP}│${RESET} ${C_SEP}%-${W_GPU}s${RESET} ${C_SEP}│${RESET} ${C_SEP}%-${W_PSTATE}s${RESET} ${C_SEP}│${RESET} ${C_SEP}%-${W_UTIL}s${RESET} ${C_SEP}│${RESET} ${C_SEP}%-${W_VRAM}s${RESET} ${C_SEP}│${RESET} ${C_SEP}%-${W_TEMP}s${RESET} ${C_SEP}│${RESET} ${C_SEP}%-${W_PWR}s${RESET} ${C_SEP}│${RESET}\n" \
        "$1" "$2" "$3" "$4" "$5" "$6" "$7"
}


# ── Static frame: printed once ────────────────────────────────────────────────

print_static_frame() {
    # clear screen once (does not reset terminal/colors)
    printf "\033c"   
    printf "${C_HDR}  ⬡  GPU Monitor  ${RESET}${C_SEP}—  ${C_HDR}refresh every %ss${RESET}\n\n" "$INTERVAL"
    hline ┌ ┬ ┐
    hrow     "TIME"       "GPU#" "STATE"  "GPU [%]"  "VRAM [MiB]"        "TEMP [°C]" "POWER [W]"
    hrow_dim "[HH:MM:SS]" ""     ""       ""          "used/total (free)" ""          "draw/max"
    hline ├ ┼ ┤
}


# ── Count GPUs once so we know how many data rows to expect ───────────────────

GPU_COUNT=$(nvidia-smi --query-gpu=index --format=csv,noheader 2>/dev/null | wc -l)
[ "$GPU_COUNT" -lt 1 ] && GPU_COUNT=1


# ── Make a box for the Legend ─────────────────────────────────────────────────

legend_box() {
    local W=42
    # shellcheck disable=SC2059
    printf "${C_SEP}┌$(seg $((W)))┐${RESET}\n"
    printf "${C_SEP}│${RESET} ${C_HDR}GPU   [%%]   ${C_BLUE}● <80${RESET}    ${C_WARN}● 80–95${RESET}   ${C_CRIT}● >95${RESET}     ${C_SEP}│${RESET}\n"
    printf "${C_SEP}│${RESET} ${C_HDR}VRAM  [%%]   ${C_OK}● <80${RESET}    ${C_WARN}● 80–95${RESET}   ${C_CRIT}● ≥95${RESET}     ${C_SEP}│${RESET}\n"
    printf "${C_SEP}│${RESET} ${C_HDR}TEMP  [°C]  ${C_OK}● <70${RESET}    ${C_WARN}● 70–86${RESET}   ${C_CRIT}● >86${RESET}     ${C_SEP}│${RESET}\n"
    printf "${C_SEP}│${RESET} ${C_HDR}POWER [W]   ${C_OK}● <80${RESET}    ${C_WARN}● 80–100${RESET}  ${C_CRIT}● >100${RESET}    ${C_SEP}│${RESET}\n"
    printf "${C_SEP}└$(seg $((W)))┘${RESET}\n"
}


# ── Print blank placeholder rows + footer + legend (printed once) ─────────────

print_bottom_frame() {
    # shellcheck disable=SC2059
    local i
    for (( i=0; i<GPU_COUNT; i++ )); do
        printf "${C_SEP}│${RESET} %-${W_TIME}s ${C_SEP}│${RESET} %-${W_GPU}s ${C_SEP}│${RESET} %-${W_PSTATE}s ${C_SEP}│${RESET} %-${W_UTIL}s ${C_SEP}│${RESET} %-${W_VRAM}s ${C_SEP}│${RESET} %-${W_TEMP}s ${C_SEP}│${RESET} %-${W_PWR}s\n" \
            "" "" "" "" "" "" ""
    done
    hline └ ┴ ┘
    printf "\n"

    # This '\n' is a place-holder for print_vram_bar() <vram_pct>
    printf "\n"

    legend_box
    printf "\n"
    printf "  ${C_HDR}Press ${C_LGRY}[Ctrl-c]${RESET}${C_HDR} to exit.${RESET}\n"

    if [ "$DEBUG" -eq 1 ]; then
        printf "\n"
        echo "  MAX_SM_CLOCK : $MAX_SM_CLOCK Mhz"
        echo "  MAX_POWER    :  $MAX_POWER W"
    fi
}

# Lines from cursor (after last header hline) to get back up to row N (0-indexed)
#   GPU_COUNT data rows + 1 (└) + 1 (blank) + 1 (bar) + 1 (┌) + 4 (legend) + 1 (┘) + 1 (blank) + 1 (exit) = GPU_COUNT + 11
if [ "$DEBUG" -eq 1 ]; then
    LINES_BELOW=$(( GPU_COUNT + 14 ))	# With DEBUG info
else
    LINES_BELOW=$(( GPU_COUNT + 11 ))	# With legend_box() + VRAM progress bar
fi

# ── Overwrite a single data row in place ──────────────────────────────────────

# $1 = 0-indexed row number
update_row() {
    # shellcheck disable=SC2059
    local row_idx=$1
    shift

    local time_only=$1 idx=$2 pstate=$3 gpu_util=$4 vram=$5 mem_total=$6 mem_free=$7 temp=$8 pwr=$9 pwr_max=${10}

    local vram_pct=0
    [ "$mem_total" -gt 0 ] 2>/dev/null && vram_pct=$(( vram * 100 / mem_total ))
    #export VRAMP=$vram_pct
    VRAMP=$vram_pct

    local C_VRAM;   C_VRAM="$(vram_color  "$vram_pct")"
    local C_T;      C_T="$(temp_color     "$temp")"
    local C_P;      C_P="$(power_color    "$pwr")"
    local C_U;      C_U="$(gpu_color      "$gpu_util")"

    local p_time;       p_time=$(printf "%-${W_TIME}s"  "$time_only")
    local p_idx;        p_idx=$(printf  "%${W_GPU}s"    "$idx")
    local p_pstate;     p_pstate=$(printf "%-${W_PSTATE}s" "$pstate")
    local p_util;       p_util=$(printf "%-${W_UTIL}s"  "${gpu_util} %")
    local p_pwr_draw;   p_pwr_draw=$(printf "%6s" "$pwr")
    local p_pwr_max;    p_pwr_max=$(printf  "%-10s" "$pwr_max")

    # Move cursor up from bottom of printed block to the target row
    # We are currently sitting after the last line printed; move up enough lines.															   
    local lines_up=$(( LINES_BELOW - row_idx ))
    printf "\033[%dA\r" "$lines_up"

    # Overwrite the row
    printf "${C_SEP}│${RESET}"
    printf " ${C_TIME}%s${RESET} ${C_SEP}│${RESET}" "$p_time"
    printf " ${C_IDX}%s${RESET} ${C_SEP}│${RESET}"  "$p_idx"
    printf " ${C_HDR}%s${RESET} ${C_SEP}│${RESET}"  "$p_pstate"
    printf " ${C_U}%s${RESET} ${C_SEP}│${RESET}"    "$p_util"
    printf " ${C_VRAM}%5d${RESET} / ${C_BLUE}%5d${RESET} ${C_SEP}(${RESET}${C_HDR}%-4d${RESET}${C_SEP})${RESET}     ${C_SEP}│${RESET}" "$vram" "$mem_total" "$mem_free"
    printf " ${C_T}%s °C    ${RESET} ${C_SEP}│${RESET}"  "$temp"
    printf " ${C_P}%s${RESET} / ${C_BLUE}%s${RESET} ${C_SEP}│${RESET}" "$p_pwr_draw" "$p_pwr_max"

    # Move cursor back down to bottom
    printf "\033[%dB\r" "$lines_up"
}


# ── Poll: read nvidia-smi, update each row in place ───────────────────────────

poll() {
    local row_idx=0
    while IFS=',' read -r ts idx pstate gpu_util mem_used mem_res mem_total mem_free temp pwr pwr_max; do
        ts=$(echo "$ts"               | xargs)
        idx=$(echo "$idx"             | xargs)
        pstate=$(echo "$pstate"       | xargs | cut -c1-10)
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

        update_row "$row_idx" "$time_only" "$idx" "$pstate" "$gpu_util" "$vram" "$mem_total" "$mem_free" "$temp" "$pwr" "$pwr_max"
        row_idx=$(( row_idx + 1 ))
    done < <(nvidia-smi \
        --query-gpu=timestamp,index,pstate,utilization.gpu,memory.used,memory.reserved,memory.total,memory.free,temperature.gpu,power.draw,power.max_limit \
        --format=csv,noheader,nounits 2>/dev/null)
    update_vram_bar
}

# ── Init ───────────────────────────────────────────────────────────────────────

# Catch [Ctrl-c] key-press
trap 'printf "\033[0m\n"; exit 0' INT TERM

[ "$DEBUG" -eq 1 ] && get_card_powers

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
