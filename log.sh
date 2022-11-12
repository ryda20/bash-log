#!/bin/bash

## Variables ##
__BLOG_NC=$'\001'"$(tput sgr0)"$'\002'

__BLOG_COLORS[0]=$'\001'"$(tput setaf 0)"$'\002'
__BLOG_COLORS[1]=$'\001'"$(tput setaf 2)"$'\002'
__BLOG_COLORS[2]=$'\001'"$(tput setaf 3)"$'\002'
__BLOG_COLORS[3]=$'\001'"$(tput setaf 190)"$'\002'
__BLOG_COLORS[4]=$'\001'"$(tput setaf 153)"$'\002'
__BLOG_COLORS[5]=$'\001'"$(tput setaf 4)"$'\002'
__BLOG_COLORS[6]=$'\001'"$(tput setaf 5)"$'\002'
__BLOG_COLORS[7]=$'\001'"$(tput setaf 6)"$'\002'
# __BLOG_COLORS[8]=$'\001'"$(tput setaf 1)"$'\002'
# __BLOG_COLORS[9]=$'\001'"$(tput setaf 7)"$'\002'

__BLOG_COLORS_SIZE=${#__BLOG_COLORS[@]}
__BLOG_COLORS_INDEX=0
__BLOG_COLORS_INDEX_PRE=0
__BLOG_COLORS_RANDOM=${__BLOG_COLORS[$__BLOG_COLORS_INDEX]}  # default color is black

__BLOG_DEBUG=0

log_debug() {
	# show log only when have log_debug.txt file or __BLOG_DEBUG env is greater than 0
	if [ -f "log_debug.txt" -o $__BLOG_DEBUG -gt 0 ]; then
		log "${1}"
	fi
}


# log print out log
# log [options] message
# 	options:
#		<string> --prefix | -pf: allow to set prefix value
#		<string> --suffix | -sf: allow to set suffix value
#		<number> --line_width | -lw: allow to change line width value
#		<string> --padding_str | -ps: allow to change padding string
#		<switch> --header | -h: allow to call log_header from log function
#		<switch> --title | -t: allow to call log_title from log function
#		<switch> --empty | -e: allow to call log_empty from log function
#		<switch> --end | -ed: allow to call log_end_from log function
log() {
	local args=("$@")
	local str prefix suffix line_width padding_str
	local is_header is_title title_str is_step is_end is_empty
	while [[ $# -gt 0 ]]; do
		case $1 in 
		--end|-ed)
			is_end=1; log_debug "got end switch"; break;;
		--empty|-e)
			is_empty=1; log_debug "got empty switch"; break;;
		--step|-sp)
			is_step=1; log_debug "got step switch";break;;
		--header|-hr)
			is_header=1; log_debug "got header switch"; break;;
		--title|-t)
			is_title=1; title_str="$2"; log_debug "got title switch with value: $2"; shift; break;;
		--suffix|-sf)
			shift; suffix="$1"; log_debug "got suffix: $1";;
		--prefix|-pf)
			shift; prefix="$1"; log_debug "got prefix: $1";;
		--line_width|-lw)
			shift; line_width="$1"; log_debug "got line_width: $1";;
		--padding_str|-ps)
			shift; padding_str="$1"; log_debug "got padding_str: $1";;
		*)
			str="$1"; log_debug "got str: $1";;
		esac
		shift
	done

	# check if input set --step
	[[ $is_step -gt 0 ]] && log_step "${args[@]}" && return
	# check if input set --title
	[[ $is_title -gt 0 ]] && [[ -n "$title_str" ]] && log_title "${args[@]}" && return
	# check if input set --header
	[[ $is_header -gt 0 ]] && log_header "${args[@]}" && return
	# check if --empty, -emp
	[[ $is_empty -gt 0 ]] && log_empty "${args[@]}" && return
	# check if --end, -e
	[[ $is_end -gt 0 ]] && log_end "${args[@]}" && return


	# check and set default values
	prefix=${prefix:-"# "}
	suffix=${suffix:-""}
	line_width=${line_width:-${RF_LINE_WIDTH:-90}}
	padding_str="${padding_str:-" "}"
	header=${header:-0}
	str=` __blog_replace_tab_by_space "${str}" `

	local padding=$(( line_width - ${#str} - ${#prefix} - ${#suffix} ))

	log_debug "prefix: $prefix, suffix: $suffix, line_width: $line_width, padding: $padding"
	
	__blog_repeat --count $padding --prefix "${__BLOG_COLORS_RANDOM}${prefix}${str}" --suffix "${suffix}${__BLOG_NC}" "$padding_str"
}

# log_header log text as header
# allow to change line_width
# log_header [--prefix x --suffix y --line_width numb] "log text here"
# or
# log_header "log text here" [--prefix x --suffix y --line_width numb]
log_header() {
	local str line_width prefix suffix padding_str
	while [[ $# -gt 0 ]]; do
		case $1 in 
		--header|-hr) shift; log_debug "got passing from log, so, skip this one";;
		--suffix|-sf) shift; suffix="$1"; log_debug "got suffix: $1";;
		--prefix|-pf) shift; prefix="$1"; log_debug "got prefix: $1";;
		--line_width|-lw) shift; line_width="$1"; log_debug "got line_width: $1";;
		--padding_str|-ps) shift; padding_str="$1"; log_debug "got padding_str: $1";;
		*) str="$1"; log_debug "got str: $1";;
		esac
		shift
	done
	# check and set default values
	prefix="${prefix:-"####"}"
	suffix="${suffix:-"#"}"
	line_width=${line_width:-${RF_LINE_WIDTH:-90}}
	padding_str="${padding_str:-"="}"
	str=` __blog_replace_tab_by_space "${str}" `
	
	__blog_random_color_gen
	log_debug "random color to "
	str="${prefix} ${str} ${prefix}" # append 2 prefix to str
	local padding=$(( line_width - ${#str} - ${#suffix} ))
	
	log_debug "prefix: $prefix, suffix: $suffix, line_width: $line_width, padding: $padding"

	__blog_repeat --count ${padding} --prefix "${__BLOG_COLORS_RANDOM}${str}" --suffix "${suffix}${__BLOG_NC}" "${padding_str}"
}

# log_title create a log have title and content
# log_title [--title "title here" --prefix x --suffix y --line_width numb] "log text here"
# or
# log_title "log text here" [--title "title here" --prefix x --suffix y --line_width numb]
log_title() {
	local title str line_width prefix suffix padding_str ifs
	while [[ $# -gt 0 ]]; do
		case $1 in 
		--title|-t) shift; title="$1"; log_debug "got title: $1";;
		--suffix|-sf) shift; suffix="$1"; log_debug "got suffix: $1";;
		--prefix|-pf) shift; prefix="$1"; log_debug "got prefix: $1";;
		--line_width|-lw) shift; line_width="$1"; log_debug "got line_width: $1";;
		--padding_str|-ps) shift; padding_str="$1"; log_debug "got padding_str: $1";;
		--ifs) shift; ifs="$1"; log_debug "got ifs: $1";;
		*) str="$1"; log_debug "got str: $1";;
		esac
		shift
	done
	# check and default value
	prefix="${prefix:-"# "}"
	suffix="${suffix:-"#"}"
	line_width=${line_width:-${RF_LINE_WIDTH:-90}}
	padding_str="${padding_str:-" "}"
	title="${title:-""}"
	str=` __blog_replace_tab_by_space "${str}" `
	
	ifs=${ifs:-$'\n'}

	# re-calculate line_width with prefix and suffix
	line_width=$(( line_width + ${#prefix} + ${#suffix} ))

	local padding=0

	# print out header
	log_header "${title}" --line_width ${line_width}
	
	local saveIFS="$IFS" && IFS=$ifs
	for line in ${str}; do
		line="$( __blog_replace_tab_by_space "${line}" )"
		padding=$(( line_width - ${#line} - ${#prefix} - ${#suffix} ))
		
		# log_debug "line len: ${#line}, padding: ${padding}"
		
		[[ $padding -lt 1 ]] && padding=0
		__blog_repeat --count ${padding} --prefix "${prefix}${line}" --suffix "${suffix}" "${padding_str}"
	done
	log_end --line_width ${line_width}
	IFS="$saveIFS"
}

# log_end log with no text - seperated line
log_end() {
	local line_width prefix suffix padding_str
	while [[ $# -gt 0 ]]; do
		case $1 in 
		--suffix|-sf) shift; suffix="$1"; log_debug "got suffix: $1";;
		--prefix|-pf) shift; prefix="$1"; log_debug "got prefix: $1";;
		--line_width|-lw) shift; line_width="$1"; log_debug "got line_width: $1";;
		--padding_str|-ps) shift; padding_str="$1"; log_debug "got padding_str: $1";;
		esac
		shift
	done
	line_width=${line_width:-${RF_LINE_WIDTH:-90}}
	prefix="${prefix:-"#"}"
	suffix="${suffix:-"#"}"
	padding_str="${padding_str:-"="}"
	local padding=$(( line_width - ${#prefix} - ${#suffix} )) # -2 because i want to keep line_width but i was added 2 #
	__blog_repeat --count ${padding} --prefix "${prefix}" --suffix "${suffix}" "${padding_str}"
	# echo # make new line
}

log_empty(){
	log_end --prefix " " --suffix " " --padding_str " "
}


__BLOG_STEP_SEP=$'\n'
__BLOG_STEP_MESSAGE=""
__BLOG_STEP_X=0
__BLOG_STEP_Y=0

# log_step create a log with keeping the step in the top of console for easy following
log_step() {
	clear
	__BLOG_STEP_MESSAGE="${__BLOG_STEP_MESSAGE}${__BLOG_STEP_SEP}${@}\n"
	tput cup ${__BLOG_STEP_X} ${__BLOG_STEP_Y} 
	local saveIFS=$IFS
	IFS=${__BLOG_STEP_SEP}
	for msg in ${__BLOG_STEP_MESSAGE}; do
		[[ -z "${#msg}" ]] && continue
		if [[ "${msg:0:7}" == "result:" ]]; then
			log "${msg}" --suffix "#"
			continue
		fi
		# [[ "${msg:0:6}" == "title:" ]] && log_title "${msg:6}" && continue
		log_header "${msg}"
	done
	IFS=$saveIFS
	
	# __BLOG_STEP_Y=$((__BLOG_STEP_Y + 1))
	# __BLOG_STEP_Y=$((__BLOG_STEP_Y + 1))
}

# log_step_title() {
# 	log_step "title: => ${@}"
# }

log_step_result(){
	log_step "result: => ${@}"
}

log_step_reset() {
	__BLOG_STEP_MESSAGE=""
	__BLOG_STEP_X=0
	__BLOG_STEP_Y=0
}

__blog_replace_tab_by_space() {
	echo -e "${1}" | sed 's/\t/    /g'
}

# Repeat given char N times using shell function
# __blog_repeat "repeat str" [--prefix x --suffix y --count numb]
# or
# __blog_repeat [--prefix x --suffix y --count numb] "repeat str"
__blog_repeat() {
	local str count prefix suffix
	while [[ $# -gt 0 ]]; do
		case $1 in 
		--suffix) shift; suffix="$1"; log_debug "got suffix: $1";;
		--prefix) shift; prefix="$1"; log_debug "got prefix: $1";;
		--count) shift; count="$1"; log_debug "got count: $1";;
		*) str="$1"; log_debug "got str: $1";;
		esac
		shift
	done
	# check and default values
	count=${count:-${RF_LINE_WIDTH:-90}}
	prefix="${prefix:-}"
	suffix="${suffix:-}"

	# add prefix on start
	echo -en "${__BLOG_COLORS_RANDOM}${prefix}"
	if [[ $count -gt 0 ]]; then
		# range start at 1
		local range=$( seq 1 ${count} )
		for i in $range; do echo -n "${str}"; done
	fi
	echo -e "${suffix}${__BLOG_NC}"
}

__blog_random_color_gen() {
	# generate random color, RANDOM is a bash shell value
	__BLOG_COLORS_INDEX=$(( RANDOM % __BLOG_COLORS_SIZE ))
	if [[ ${__BLOG_COLORS_INDEX} -eq ${__BLOG_COLORS_INDEX_PRE} ]]; then
		__BLOG_COLORS_INDEX=$(( RANDOM % __BLOG_COLORS_SIZE ))
	fi
	__BLOG_COLORS_INDEX_PRE=${__BLOG_COLORS_INDEX}
	__BLOG_COLORS_RANDOM=${__BLOG_COLORS[$__BLOG_COLORS_INDEX]}
}

# starting
# "$@"
