#!/usr/bin/env bash
# pretty-help-llama.sh - A bash script to parse and colorise the help output from llama-*.exe
#
# author	: eabase
# version	: 1.0.7
# date      : 2026-05-15
# repo url  : https://github.com/eabase/gpu-watch
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
#
# -single-dash-option  			# color-1
# --double-dash-option 			# color-2
# [option,list,items]			# color-3
# ENVIRONMENT_VARIABLES			# color-4
# default: variable				# color-5
# <option-value-N>				# color-6
# ----- section header -----  	# color-7
#------------------------------------------------------

# Enable alias expansion (for using alias inside functions)
shopt -s expand_aliases


#------------------------------------------------------
# Helper Functions - Color
#------------------------------------------------------

#----------------------------
# ANSI Color Code variables
##----------------------------
# see [1] and:
#   gpu-watch.sh
#   /c/mybin/cygbin/color_names.sh
#----------------------------
# ANSI Control Codes
# CRST='\e[0m'  # ANSI RESET
# PFX='\e['     # ANSI *prefix*

# Dark
# CD_BLK='0;30'	# Black
# CD_RED='0;31'	# Dark Red
# CD_GRN='0;32'	# Dark Green
# CD_YEL='0;33'	# Dark Yellow
# CD_BLU='0;34'	# Dark Blue
# CD_MAG='0;35'	# Dark Magenta
# CD_CYA='0;36'	# Dark Cyan
# CD_WHT='0;37'	# Dark White

# Bright
# CB_BLK='1;30'	# Bright Black --> Gray
# CB_RED='1;31'	# Bright Red
# CB_GRN='1;32'	# Bright Green
# CB_YEL='1;33'	# Bright Yellow
# CB_BLU='1;34'	# Bright Blue
# CB_MAG='1;35'	# Bright Magenta
# CB_CYA='1;36'	# Bright Cyan
# CB_WHT='1;37'	# Bright White

# RGB (TBA) Examples:
# CR_256='\e[38;5;100m'          # '\e[38;5;Nm'      -- where N = (0-255)
# CR_RGB='\e[38;2;255,0,0m'      # '\e[38;2;R;G;Bm'  -- where we used "Red = (R,G,B) = (255,0,0)"

# Test GREP colors with:
#cat TT.txt | GREP_COLOR='1;36' grep --color=always -E "speculative"        # Bright Cyan
#cat TT.txt | GREP_COLOR='1;37;41' grep --color=always -E "speculative"     # 

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
    local TT=" $1 "
    printf '\U2500%.0s' $(seq ${#TT})
	# colorize header:
    echo -e "\n\e[1;33m${TT}\e[0m"
    printf '\U2500%.0s' $(seq ${#TT})
	echo
}

# We have to export headline(), as it will be used in a subshell in replace_headers().
export -f headline

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
	echo -e "\e[0;32mok\e[0m"
}


#--------------------------------------
# Alias - Grep Color
#--------------------------------------
# TIPS:
# - Convert into functions for readability!
# - Perl RegEx (-P) extensions doesn't seem to work 
#   when used in an grep alias!
#
# NOTES
#
# To get content of "(env: AAAAA)"
# | grep --color=always -P '\(env:\s*\K[^)]+(?=\))|$'
#
# To get content of "(default: AAAAA)" (multi-line compatible)
# | grep --color=always -Pz '(?s)\(default:\s*\K[^)]+|$'
#
# -- WEIRD --
# This works
# cat llamacli-help.txt | grep --color=always -Pz '(?s)\(default:\s*\K[^)]+|$'
# But using it in an alias fails!
#
# To get content of "('single-quoted')"
# ToDo: Not yet solved - unknown issue
#--------------------------------------

# Is this a good idea?
# export GREP_OPTIONS='--color=always'

alias GC1='GREP_COLOR='\''33'\'' grep --color=always -E '\''\-\-[a-zA-Z][a-zA-Z0-9\-]+[ =]*|$'\'' '	# double dash options 	: "--some-option-123"
alias GC2='GREP_COLOR='\''1;36'\'' grep --color=always -E '\''[ ^]\-[a-zA-Z\-]+|$'\'' '				# single dash options 	: "-some-option" (any place)

#alias GC3='GREP_COLOR='\''36'\'' grep --color=always -E '\''[ ]+\(env: [A-Z_]*\)|$'\'' '			# environment vaiable 	: "(env: ENVIRONMENT_VAR)"
alias GC3='GREP_COLOR='\''36'\'' grep --color=always -P '\''\(env:\s*\K[^)]+(?=\))|$'\'' '			# environment vaiable 	: "(env: ENVIRONMENT_VAR)"

perl_grep_def () {
	GREP_COLOR='1;31' grep -P '(?s)\(default:\s*\K[^)]+|$' --color=always		                    # deafult values      	: "(default: value)"
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

#--------------------------------------
# Create Colored Section Headers
#--------------------------------------
replace_headers() {
    awk '/^-{5} .* -{5}$/ {
        gsub(/^-{5} | -{5}$/, "")
        system("headline \"" $0 "\"")
        next
    }
    { print }' 
}

alias GC8='replace_headers'

#-------------------------------------------------------------
# Finally we try to highlight some common option *values* 
# that are hard to grep more generically, such as:
#   N, <xxxx>, [xxx,yyy], {aaa, bbb, ccc, ... }
#   
# Using color: Bright Blue? 1;34
#-------------------------------------------------------------
fGC9() {
    GREP_COLOR='1;34' grep --color=always -E " [M|N] |$"            |   # " N "
    #GREP_COLOR='1;34' grep --color=always -E "\s{1,}[M|N]\s{1,}|$" |   # " N "
    GREP_COLOR='1;34' grep --color=always -E "\s[A-Z_]+\s|$"            # " SOME_VARIABLE "
    #GREP_COLOR='1;34' grep --color=always -E "\s<[^ \<\>]>\s|$"    |   # " <xxx,yyy,...> "     - WARN: Not rubust as can have spaces
    #GREP_COLOR='1;34' grep --color=always -E "\s\[[^ \[\]]\]\s|$"  |   # " [xxx,yyy] "         - WARN: Not rubust as can have spaces
    #GREP_COLOR='1;34' grep --color=always -E "\sN\s|$"             |   # " {aaa, bbb, ... } "  - WARN: Not rubust as can have spaces
    #GREP_COLOR='1;34' grep --color=always -E "\sN\s|$"                 # " N "
}
alias GC9='fGC9'


#--------------------------------------
# Putting it together...
#--------------------------------------
# Q: Why do we need to parse early?
# A: Because the remaining lines gets confused by the injected ANSI color codes.
#   - We have to parse the headers (GC8) early      - little risk of confusion
#   - We have to parse the "common options" early   - some risk for confusion
#--------------------------------------
alias GALL='GC8 | GC9 | GC1 | GC2 | GC3 | GC4 | GC5 | GC6'


#------------------------------------------------------
# Helper Functions - commands
#------------------------------------------------------

dump_embedded_env_vars() {
    local LLAMA_EXE=$1
    # Dump all environment variables from llama's '--help'
    #cat llamacli-help.txt | grep -E "(env: [A-Z_]+)" | sed -e 's/(env: //i' -e 's/)//i' | tr -d "\ " | sort
    LLAMA_EXE --help 2>/dev/null | grep -E "(env: [A-Z_]+)" | sed -e 's/(env: //i' -e 's/)//i' | tr -d "\ " | sort
}

#--------------------------------------
# Parse CLI options
#--------------------------------------
# We want to use options like this:
#   pretty-help-llama [options: -h -? -e] <binary[.exe]>
#   ./pretty-help-llama.sh llama-cli.exe
#   ./pretty-help-llama.sh llama-cli
#--------------------------------------
parse_options() {

    local LLAMA_EXE=$1      # The selected llama binary (llama-*.exe)

    # Handle options
    while getopts "he" opt; do
        case $opt in
            e) dump_embedded_env_vars "$LLAMA_EXE"; exit 0 ;;  # Dump the text embedded environment variables '(env: XXX)'' from selected LLAMA_EXE --help ouput
            h) help; exit 0 ;;      # '-h'
            ?) help; exit 1 ;;      # Error
        esac
    done

    # Read piped input from stdin
    if [ -p /dev/stdin ]; then
        echo
        headline "Parsing Generic Help from pipe"
        echo
        cat | GALL
    else
        $LLAMA_EXE --help 2>/dev/null | GALL
    fi
}

#--------------------------------------
# Main
#--------------------------------------

main () {
	local TIT=$1            # "LLAMA_EXE" - The selected binary (*.exe)
    parse_options $TIT

    echo -e "\n\e[0;32mok\e[0m\n"
	exit 0
}

main "$@"

#------------------------------------------------------------------------------
#  END
#------------------------------------------------------------------------------
