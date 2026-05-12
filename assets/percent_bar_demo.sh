#!/bin/bash
# shellcheck disable=SC2059


# Source - https://stackoverflow.com/a/68298090
# Posted by F. Hauri  - Give Up GitHub, modified by community. See post 'Timeline' for change history
# Retrieved 2026-05-09, License - CC BY-SA 4.0

echo -e "\n\nThis is a full demo for using percentBar() from SO answer here:"
echo -e "https://stackoverflow.com/a/68298090\n\n"

#--------------------------------------------------------------------
# Initial setup
#--------------------------------------------------------------------

# Calculate usable full Terminal width
#COLUMNS=$(tput cols) bar=()
COLUMNS=60 bar=()

doDelay() {
    local delay=.0125 userKey
    case ${percnt%?} in
        0.0|33.[36]|49.8|50.1|66.[69]|99.9|100.0) delay=.5 ;;
    esac
    IFS= read -rst $delay -n 1 userKey && case $userKey in
        n ) return 1 ;;
        q ) return 2 ;;
    esac
    return 0
}

chars=( '\U2588\U2589\U258A\U258B\U258C\U258D\U258E\U258F' ''
        '\U2597\U2584\U2596' '\U257A\U2501\U2578' '\U2576\U2500\U2574' \
                             '\U259D\U2580\U2598' '\U2830\U2836\U2806')
mapfile -t printchars < <(printf '%b\n' "${chars[@]:---default--}")
mapfile -t printchars < <(printf '%s\n' "${printchars[@]//?/ &}")
mapfile -t printchars < <(printf '%s\n' "${printchars[@]/# }")


#--------------------------------------------------------------------
# Helper Functions
#--------------------------------------------------------------------

percent(){
    local p=00$(($1*100000/$2))
    printf -v "$3" %.2f ${p::-3}.${p: -3}
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



percentBar2 () {
    local prct totlen=$(( 2 * $2 )) lastchar lhs rhs \
          lmr=${4:-'\U257a\U2501\U2578'} sep="${5:-\\e[1m:\\e[0;2m}"
    printf -v lmr %b "$lmr"
    printf -v prct %.2f "$1"
    ((prct=10#${prct/.}*totlen/10000, prct%2)) && lastchar="${lmr:2}"
    printf -v lhs '%*s' $((prct/2)) '';
    printf -v rhs '%*s' $(((totlen-prct-1)/2)) '';
    [[ -z $lastchar ]] && (( totlen > prct )) && rhs="${lmr::1}$rhs";
    printf -v "$3" '%b%b%b%b%b\e[0m' "${sep%:*}" "${lhs// /${lmr:1:1}}" \
            "$lastchar" "${sep#*:}" "${rhs// /${lmr:1:1}}"
}

#--------------------------------------------------------------------
# Main
#--------------------------------------------------------------------

printf '\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\e[20A\e7' &&
for thm in '' '\e[32;1m:\e[0;30m' '\e[38;5;125m:\e[38;5;95m'; do
    thmFg="${thm%:*}" thmBg="${thm#*:}"
    thmBg="${thmBg/\[0;/[}"
    tthm="${thmFg}${thmBg/\[3/[4}"
    tthm="${tthm/m\\e[/;}"
    printThm="${thm:---default--}"
    str="\\e8\e[AColors: \47%s\47 \47%b\U259A\U259A\U259A\U259A\e[0m\47  \47%s"
    str+="\47  \47%b\U259A\U259A\e[0;1m\47:\e[0m\47%b\U259A\U259A\e[0m\47\n"
    printf "$str" "${tthm:---default--}" "$tthm" "${printThm/:/\':\'}" \
           "${thm%:*}" "${thm#*:}"
    for i in {0..9999..11} 10000; do  # {0..9999..33}
        o=0 i=0$i
        printf -v percnt %0.2f "${i::-2}.${i: -2}"
        for l in 1 3 12 $((COLUMNS)); do
            percentBar "$percnt" $l "bar[$((o++))]"
        done
        for char in "${chars[@]:1}"; do
            for l in 1 3 12 $((COLUMNS)); do
                percentBar2 "$percnt" $l "bar[$((o++))]" "$char" "$thm"
            done
        done
        str="Chars: \47%%%%b\47\nWidth 1 char \U2595%%%%%%%%b%s\e[0m\U258F, 3 c"
        str+="hars \U2595%%%%%%%%b%s\e[0m\U258F, 12 chars \U2595%%%%%%%%b%s\e[0"
        str+="m\U258F, or full width:%%7.2f%%%%%%%%%%%%%%%%\n%%%%%%%%b%s\e[0m\n"
        printf -v str "$str"    "${bar[@]}"
        printf -v str "$str" "$percnt"{,,,,,,}
        printf -v str "$str" "${printchars[@]}"
        printf "\e8${str%$'\n'}" "$tthm"{,,,}
        doDelay || break $?
    done
done

#--------------------------------------------------------------------
#  END
#--------------------------------------------------------------------
