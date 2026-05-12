#!/usr/bin/env bash
# my_percent_bar.sh - An ANSI colored bash progress bar demo
# shellcheck disable=SC2059

#----------------------------------------------------------
# Init
#----------------------------------------------------------

echo -e "\nThe following function shows a colored horizontal bar whose length"
echo -e "is given by the provided percentage (0-100)."
echo -e "\nThe colors used are:\n"

echo -en 'For Background         : use DarkGray (238)      # [48;5;235m'; echo '  # echo -e "\e[48;5;235m ABCD_1234 \e[0m"'
echo -en 'For Foreground (  <70%): use Dark Green          # [0;32m'    ; echo '      # echo -e "\e[0;32m\e[48;5;235m ABCD_1234 \e[0m"'
echo -en 'For Foreground (70-90%): use Dark Orange         # [0;33m'    ; echo '      # echo -e "\e[0;33m\e[48;5;235m ABCD_1234 \e[0m"'
echo -en 'For Foreground (  >90%): use Dark Red            # [0;31m'    ; echo '      # echo -e "\e[0;31m\e[48;5;235m ABCD_1234 \e[0m"'

echo -e "\nUsage:"
echo -e "  . my_percent_bar.sh; print_vram_bar"
echo -e "  print_vram_bar <percentage>\n"

#----------------------------------------------------------
# Helper Functions
#----------------------------------------------------------

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


demo_vram_bar () {
	# We hard-code a column with of 40 (for demo purposes)
    local p BARWIDTH=$((40-7))
    echo -e "Examples:\n"
    p=47; percentBar $p $BARWIDTH bar; printf '\e[0;32m\e[48;5;235m%s\e[0m\U258f%6.2f%%' "$bar" $p; echo
    p=75; percentBar $p $BARWIDTH bar; printf '\e[0;33m\e[48;5;235m%s\e[0m\U258f%6.2f%%' "$bar" $p; echo
    p=93; percentBar $p $BARWIDTH bar; printf '\e[0;31m\e[48;5;235m%s\e[0m\U258f%6.2f%%' "$bar" $p; echo

    echo -e "\nLoading example:\n"
	# Green bar on DarkGray background
	for i in {0..10000..33} 10000;do
		i=0$i
		printf -v p %0.2f ${i::-2}.${i: -2}
		percentBar $p $((40-7)) bar
		printf '\r\e[0;32m\e[48;5;235m%s\e[0m%6.2f%%' "$bar" $p
		read -srt .002 _ && break
	done
}

# Original:
# for i in {0..10000..33} 10000;do i=0$i; printf -v p %0.2f ${i::-2}.${i: -2}; percentBar $p $((40-7)) bar; printf '\r\e[0;32m\e[48;5;235m%s\e[0m%6.2f%%' "$bar" $p; read -srt .002 _ && break; done	# Green on DarkGray

print_vram_bar () {
	#BARWIDTH=$((COLUMNS-7))
	local p=$1 BARWIDTH=$((40-7))

	echo -e "\nYour progress bar with: \$p=$p %\n"

	# This line is used for progress loop and has uses '\r' and not any last '\n'.
	#p=$1; percentBar $p $BARWIDTH bar; printf '\r\e[0;32m\e[48;5;235m%s\e[0m\U258f%6.2f%%' "$bar" $p

	if [ "$p" -lt 70 ]; then
		percentBar $p $BARWIDTH bar; printf '\r\e[0;32m\e[48;5;235m%s\e[0m\U258f%6.2f%%' "$bar" $p	# Green
	elif [ "$p" -gt 90 ]; then
		percentBar $p $BARWIDTH bar; printf '\r\e[0;31m\e[48;5;235m%s\e[0m\U258f%6.2f%%' "$bar" $p	# Red
	else
		percentBar $p $BARWIDTH bar; printf '\r\e[0;33m\e[48;5;235m%s\e[0m\U258f%6.2f%%' "$bar" $p	# Orange
	fi
}

#----------------------------------------------------------
# Main
#----------------------------------------------------------
echo

demo_vram_bar
echo -e "\n\n"

#print_vram_bar $1
echo

#----------------------------------------------------------
#  END
#----------------------------------------------------------
