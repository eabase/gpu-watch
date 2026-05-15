#!/usr/bin/env bash
# pretty-help-llama.sh - A bash script to parse and colorise the help output from llama-*.exe
#
#
# author	: eabase
# version	: 1.0.0
# date      : 2026-05-15
# repo url  : 
#
#------------------------------------------------------------------------------
#
# Description:
#
# 	pretty-help-llama is a bash script that use grep with customized
#	ANSI coloring codes, for specific items in the output of '--help'
#	option to several llama.cpp executables, but mainly for 'llama-cli'
#	and 'llama-server'. (There are dozens more.)
#
# Usage:
#
#	pretty-help-llama -h						# Show options help, and available llama binaries
#	pretty-help-llama <binary-alias>			# llama binary alias:  [cli, server, vulcan, ...]
#	<any-binary> --help | pretty-help-llama		# pipe output from any other binary, if not from llama-*, expext issues.
#
# Examples:
#
#	pretty-help-llama cli						# parse 'llama-cli --help'
#	pretty-help-llama server					# parse 'llama-server --help'
#	llama-cli --help | pretty-help-llama		# parse piped output from 'llama-cli --help'
#
# Dependencies:
#
# 	none
#
# References:
#
#   [1] https://askubuntu.com/questions/1042234/modifying-the-color-of-grep
# 
#------------------------------------------------------------------------------

#------------------------------------------------------
# Let's fix the help UX, by adding color to the output:
#------------------------------------------------------
# llama-cli.exe --help
#										# cat /c/mybin/cygbin/color_names.sh
# --<option>		# Dark Yellow		# printf "\e[0;33mDarkYellow\n"
# -<option>			# Magenta			# printf "\e[1;35mbold Purple\n"
# [ENVIRON_VAR]		# Cyan 				# printf "\e[1;36mbold Cyan\n"
# default:			# Blue				# printf "\e[1;34mbold Blue\n"
# 'single-quoted'	# Green				# printf "\e[1;32mbold Green\n"
#					# White				# printf "\e[1;37mbold White\n"
#------------------------------------------------------
#
# -single-dash-option  			# color-1
# --double-dash-option 			# color-2
# [option,list,items]			# color-3
# ENVIRONMENT_VARIABLES			# color-4
# default: variable				# color-5
# <option-value-N>				# color-6
# ----- section header -----  	# color-7
#
#------------------------------------------------------


#--------------------------------------
# Helper Functions
#--------------------------------------

#----------------------------
# ANSI Color Code variables
#----------------------------
# TBA
# see: gpu-watch
# /c/mybin/cygbin/color_names.sh

# ANSI Control Codes
# CRST='\e[0m'

# CB_BLK='1;30'	# Bright Black -- Gray
# CB_RED='1;31'	# Bright Red
# CB_GRN='1;32'	# Bright Green
# CB_YEL='1;33'	# Bright Yellow
# CB_BLU='1;34'	# Bright Blue
# CB_MAG='1;35'	# Bright Magenta
# CB_CYA='1;36'	# Bright Cyan
# CB_WHT='1;37'	# Bright White


# CD_BLK='1;0'	# Black
# CD_RED='1;31'	# Bright Red
# CD_GRN='1;32'	# Bright Green
# CD_YEL='1;33'	# Bright Yellow
# CD_BLU='1;34'	# Bright Blue
# CD_MAG='1;35'	# Bright Magenta
# CD_CYA='1;36'	# Bright Cyan
# CD_WHT='1;37'	# Bright White


# Test GREP colors with:
#cat TT.txt | GREP_COLOR='1;36' grep --color=always -E "speculative"
#cat TT.txt | GREP_COLOR='1;37;41' grep --color=always -E "speculative"


#----------------------------
# Box Drawing Characters
#----------------------------
# https://en.wikipedia.org/wiki/Box-drawing_characters
#
# * \U2500      # thick middle line
# * \U25ac      # thick slightly dotted upper level line
# * \U2594      # thin upper level
#   \U2581      # thin lower line (for use above text)
#----------------------------

# Print a Head Line <text> enclosed by 2 lines top & bottom
# headline () { local TT=$1; printf '\U2500%.0s' $(seq ${#TT}); echo -e "\n$TT"; printf '\U2500%.0s' $(seq ${#TT}); }
headline () {
    local TT=$1
    printf '\U2500%.0s' $(seq ${#TT})
	# No color
    #echo -e "\n$TT"
	# colorize
    echo -e "\n\e[1;33m${TT}\e[0m"
    printf '\U2500%.0s' $(seq ${#TT})
	echo
}


help () {
	echo
	headline "  Pretty Help Help  "
	cat << END_OF_HELP

  **** WIP ****
  ----------------------------------------------------
  NOTE 
    This is work in progress, not all options have
    been implemented, or doesn't work as expected.
  ----------------------------------------------------

  Description:
 
    pretty-help-llama is a bash script that use grep with customized
    ANSI coloring codes, for specific items in the output of '--help'
    option to several llama.cpp executables, but mainly for 'llama-cli'
    and 'llama-server'. (There are dozens more.)
 
  Usage:
 
    pretty-help-llama -h                        # Show options help, and available llama binaries
    pretty-help-llama <binary-alias>            # llama binary alias:  [cli, server, vulcan, ...]
    <any-binary> --help | pretty-help-llama     # pipe output from any other binary, if not from llama-*, expext issues.
 
  Examples:
 
    pretty-help-llama cli                       # parse 'llama-cli --help'
    pretty-help-llama server                    # parse 'llama-server --help'
    llama-cli --help | pretty-help-llama        # parse piped output from 'llama-cli --help'
 
  Dependencies:
 
    none

END_OF_HELP
	echo
}


#--------------------------------------
# Old Test (not working) because of color code.
#--------------------------------------

#	GREP_COLOR='\''32'\'' grep --color=always -E '\''^[ ]*git [a-zA-Z][a-zA-Z\-]+|$'\'' |
#	GREP_COLOR='\''33'\'' grep --color=always -E '\''\-\-[a-zA-Z][a-zA-Z\-]+[ =]*|$'\'' |	# -- 		Dark Yellow
#	GREP_COLOR='\''35'\'' grep --color=always -E '\''[ ^]\-[a-zA-Z]+|$'\'' |                # - 		Magenta
#	GREP_COLOR='\''36'\'' grep --color=always -E '\''[ ]+\(env: [A-Z_]*\)|$'\'' |           # [A-Z_]	Cyan
#	GREP_COLOR='\''1;34'\'' grep --color=always -E '\''\(default\: .+\)|$'\'' |             # default:	Blue
#	GREP_COLOR='\''1;32'\'' grep --color=always -E '\''\'[a-z]+[\-a-z]+\'.+|$'\'' '         # 'sin-gle'	Green


#--------------------------------------
# Working CLI Solutions
#--------------------------------------

#alias llamacol='GREP_COLOR='\''33'\'' grep --color=always -E '\''\-\-[a-zA-Z][a-zA-Z\-]+[ =]*|$'\'' | GREP_COLOR='\''35'\'' grep --color=always -E '\''[ ^]\-[a-zA-Z]+|$'\'' | GREP_COLOR='\''36'\'' grep --color=always -E '\''[ ]+\(env: [A-Z_]*\)|$'\'' | GREP_COLOR='\''31'\'' grep --color=always -E '\''\(default\: .+\)|$'\'' '
#llama-cli.exe --help | llamacol | GREP_COLOR='32' grep --color=always -P "\'[a-z]+[\-]*[a-z]+\'|$" |  GREP_COLOR='35' grep --color=always -E "^-[a-zA-Z]+|$"

#--------------------------------------
# Breakdown
#--------------------------------------
#alias llamacol='
#GREP_COLOR='\''33'\'' grep --color=always -E '\''\-\-[a-zA-Z][a-zA-Z\-]+[ =]*|$'\'' | 
#GREP_COLOR='\''35'\'' grep --color=always -E '\''[ ^]\-[a-zA-Z]+|$'\'' | 
#GREP_COLOR='\''36'\'' grep --color=always -E '\''[ ]+\(env: [A-Z_]*\)|$'\'' | 
#GREP_COLOR='\''31'\'' grep --color=always -E '\''\(default\: .+\)|$'\'' ' | 		# <-- Note end single quote !
#GREP_COLOR='32' grep --color=always -P "\'[a-z]+[\-]*[a-z]+\'|$" | 
#GREP_COLOR='35' grep --color=always -E "^-[a-zA-Z]+|$"


# Enable alias expansion (for use inside functions)
shopt -s expand_aliases

alias GC1='GREP_COLOR='\''33'\'' grep --color=always -E '\''\-\-[a-zA-Z][a-zA-Z0-9\-]+[ =]*|$'\'' '	# double dash options 	: "--some-option-123"
alias GC2='GREP_COLOR='\''1;36'\'' grep --color=always -E '\''[ ^]\-[a-zA-Z\-]+|$'\'' '				# single dash options 	: "-some-option" (any place)

#alias GC3='GREP_COLOR='\''36'\'' grep --color=always -E '\''[ ]+\(env: [A-Z_]*\)|$'\'' '			# environment vaiable 	: "(env: ENVIRONMENT_VAR)"
alias GC3='GREP_COLOR='\''36'\'' grep --color=always -P '\''\(env:\s*\K[^)]+(?=\))|$'\'' '			# environment vaiable 	: "(env: ENVIRONMENT_VAR)"


# This is not working well...
#alias GC4='GREP_COLOR='\''31'\'' grep --color=always -E '\''\(default\: .+\)|$'\'' '				# deafult values      	: "(default: value)"
#alias GC4='GREP_COLOR='\''31'\'' grep --color=always -Pz '\''(?s)\(default:\s*\K[^\)]+|$'\'' '		# deafult values      	: "(default: value)"
# ... so we use a function:
perl_grep_def () {
	GREP_COLOR='1;31' grep -P '(?s)\(default:\s*\K[^)]+|$' --color=always
}
alias GC4='perl_grep_def'


alias GC5="GREP_COLOR='1;32' grep --color=always -P \"\'[a-z]+[\-]*[a-z]+\'|$\" "					# single-quoted string	: "'single-quoted'"
alias GC6='GREP_COLOR='\''1;36'\'' grep --color=always -E '\''^-[a-zA-Z]+|$'\'' '					# single-dash ooptions-2: "-some-option" (beginning of line)

#-------------------------------------------------------------
# We want the string X in '--some-option X blah blah' not in [\-\ ]
#-------------------------------------------------------------
# NOTE
# This doesn't work becuase there are many examples of text 
# like `-xxx --yyy ZZZZ -aaa`
#-------------------------------------------------------------
#perl_grep_arg () {
#	GREP_COLOR='1;32' grep -P -z '(?s)\-\-[^ ]+\s+\K[^\-][^ ]+|$' --color=always
#}
#alias GC7='perl_grep_arg'


# We have to export headline, as it will be used in a subshell in replace_headers().
export -f headline

replace_headers2() {
    awk '/^-{5} .* -{5}$/ { gsub(/^-{5} | -{5}$/, ""); system("bash -c '\''headline \"" $0 "\"'\''"); next } { print }'
}

replace_headers() {
    awk '/^-{5} .* -{5}$/ {
        gsub(/^-{5} | -{5}$/, "")
        system("headline \"" $0 "\"")
        next
    }
    { print }' 
}

alias GC8='replace_headers'

# Finally we try to highlight some common option *values* 
# that are hard to grep more generically, such as:
#   N, <xxxx>, [xxx,yyy], {aaa, bbb, ccc, ... }
#   
# Using color: Bright Blue? 1;34

fGC9() {
    GREP_COLOR='1;34' grep --color=always -E "\s[M|N]\s|$" |\               # " N "
    GREP_COLOR='1;34' grep --color=always -E "\s[A-Z_]+\s|$" |\             # " SOME_VARIABLE "
    GREP_COLOR='1;34' grep --color=always -E "\s<[^ \<\>]>\s|$" |\          # " <xxx,yyy,...> "     - WARN: Not rubust as can have spaces
    GREP_COLOR='1;34' grep --color=always -E "\s\[[^ \[\]]\]\s|$"         # " [xxx,yyy] "         - WARN: Not rubust as can have spaces
    #GREP_COLOR='1;34' grep --color=always -E "\sN\s|$" |\                  # " {aaa, bbb, ... } "  - WARN: Not rubust as can have spaces
    #GREP_COLOR='1;34' grep --color=always -E "\sN\s|$" |\                  # " N "
}
alias GC9='fGC9'


#alias GALL='GC1 | GC2 | GC3 | GC4 | GC5 | GC6'
##alias GALL='GC1 | GC2 | GC3 | GC4 | GC5 | GC6 | GC7'
#alias GALL='GC1 | GC2 | GC3 | GC4 | GC5 | GC6 | GC8'

# We have to parse the headers (GC8) early
alias GALL='GC8 | GC1 | GC2 | GC3 | GC4 | GC5 | GC6'
#alias GALL='GC8 | GC1 | GC2 | GC3 | GC4 | GC5 | GC6 | GC9'

#--------------------------------------
#--------------------------------------

# To get content of "(env: AAAAA)"
# | grep --color=always -P '\(env:\s*\K[^)]+(?=\))|$'

# To get content of "(default: AAAAA)" (multi-line compatible)
# | grep -Pz '(?s)\(default:\s*\K[^)]+|$' --color=always

# -- WEIRD! --
# This works
# cat llamacli-help.txt | grep -Pz '(?s)\(default:\s*\K[^)]+|$' --color=always

# To get content of "('single-quoted')"
# ToDo: Not yet solved - unknown issue


parse_options() {
    # Handle options
    while getopts "he" opt; do
        case $opt in
            e) EFLAG=1 ;;
            h) help; exit 0 ;;
            ?) help; exit 1 ;;
        esac
    done

    # Read piped input from stdin
    if [ -p /dev/stdin ]; then
        if [ "$EFLAG" = "1" ]; then
            # Dump all environment variables from llama's '--help'
            cat llamacli-help.txt | grep -E "(env: [A-Z_]+)" | sed -e 's/(env: //i' -e 's/)//i' | tr -d "\ " | sort
        else
            echo
	        headline "Parsing Help from $TIT"
	        echo
            
            llama-cli.exe --help | GALL
            #cat  # just pass through if no option given
        fi
    else
        help
    fi
}

#--------------------------------------
# Main
#--------------------------------------

main () {
	local TIT=$1

	echo
	headline "Parsing Help from $TIT"
	echo

    parse_options $TIT

	#llama-cli.exe --help | GALL
	#llama-cli.exe --help | GC8

	echo -e "\nok\n"
	exit 0
}

#help
#main "llama-cli"
main "$@"


#------------------------------------------------------------------------------
#  END
#------------------------------------------------------------------------------
