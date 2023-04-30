#!/bin/bash

## Variables ##
__CS=$'\001' # color start code
__CE=$'\002' # color end code
__NOCOLOR=$__CS"$(tput sgr0)"$__CE
#
__BLACK=$__CS"$(tput setaf 0)"$__CE
__RED=$__CS"$(tput setaf 1)"$__CE
__GREEN=$__CS"$(tput setaf 2)"$__CE
__YELLOW=$__CS"$(tput setaf 3)"$__CE
__BLUE=$__CS"$(tput setaf 4)"$__CE
__MAGENTA=$__CS"$(tput setaf 5)"$__CE
__CYAN=$__CS"$(tput setaf 6)"$__CE
__WHITE=$__CS"$(tput setaf 7)"$__CE
__RESET_TO_DEFAULT_COLOR=$__CS"$(tput setaf 8)"$__CE

__BLOG_COLORS[0]=$__BLACK
__BLOG_COLORS[1]=$__GREEN
__BLOG_COLORS[2]=$__YELLOW
__BLOG_COLORS[3]=$__CS"$(tput setaf 190)"$__CE
__BLOG_COLORS[4]=$__CS"$(tput setaf 153)"$__CE
__BLOG_COLORS[5]=$__BLUE
__BLOG_COLORS[6]=$__MAGENTA
__BLOG_COLORS[7]=$__CYAN

__BLOG_COLORS_SIZE=${#__BLOG_COLORS[@]}
__BLOG_COLORS_INDEX=5
__BLOG_COLORS_INDEX_PRE=0
__BLOG_COLORS_RANDOM=${__BLOG_COLORS[$__BLOG_COLORS_INDEX]}  # default color is blue

__BLOG_INTERNAL_DEBUG=0

__BLOG_ERROR=$__RED
__BLOG_INFO=$__GREEN
__BLOG_WARNING=$__YELLOW
__BLOG_DEBUG=$__MAGENTA

# the file path to save log
__BLOG_TO_FILE=""

__BLOG_TIME=1

# log_timme: enable date-time prefix or not
log_time() {
	__BLOG_TIME=${1:-1}
}
# log_to set log file path
log_to() {
	__BLOG_TO_FILE=${1:-""}
	[[ -z "$__BLOG_TO_FILE" ]] && return

	local dir=`dirname "$__BLOG_TO_FILE"`
	mkdir -p "$dir"
	touch "$__BLOG_TO_FILE"
}

# __log_debug internal debug log
__log_debug() {
	# show log only when have __log_debug.txt file or __BLOG_INTERNAL_DEBUG env is greater than 0
	if [[ -f "debug.txt" ]] || [[ $__BLOG_INTERNAL_DEBUG -gt 0 ]]; then
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
#		<switch> --error: show as error message
#		<switch> --warning: show as warning message
#		<switch> --info: show as sucess message
#		<switch> --debug: show a debug message
log() {
	local args=("$@")
	local str prefix suffix line_width padding_str
	local is_header is_title title_str is_step is_end is_empty
	local warning=0 error=0 info=0 debug=0
	while [[ $# -gt 0 ]]; do
		case $1 in 
		--warning)
			warning=1;;
		--error)
			error=1;;
		--info)
			info=1;;
		--debug)
			debug=1;;
		--end|-ed)
			is_end=1; __log_debug "got end switch"; break;;
		--empty|-e)
			is_empty=1; __log_debug "got empty switch"; break;;
		--step|-s)
			is_step=1; __log_debug "got step switch";break;;
		--header|-h)
			is_header=1; __log_debug "got header switch"; break;;
		--title|-t)
			is_title=1; title_str="$2"; __log_debug "got title switch with value: $2"; shift; break;;
		--suffix|-sf)
			shift; suffix="$1"; __log_debug "got suffix: $1";;
		--prefix|-pf)
			shift; prefix="$1"; __log_debug "got prefix: $1";;
		--line_width|-lw)
			shift; line_width="$1"; __log_debug "got line_width: $1";;
		--padding_str|-p)
			shift; padding_str="$1"; __log_debug "got padding_str: $1";;
		*)
			str="$1"; __log_debug "got str: $1";;
		esac
		shift
	done

	if [[ $is_step -gt 0 ]]; then # check if input set --step
		log_step "${args[@]}";
		return
	elif [[ $is_title -gt 0 ]]; then # check if input set --title
		log_title "${args[@]}";
		return
	elif [[ $is_header -gt 0 ]]; then # check if input set --header
		log_header "${args[@]}";
		return
	elif [[ $is_empty -gt 0 ]]; then # check if --empty, -emp
		log_empty "${args[@]}";
		return
	elif [[ $is_end -gt 0 ]]; then # check if --end, -e
		log_end "${args[@]}";
		return
	fi
	
	# check and set default values
	prefix=${prefix:-"# "}
	suffix=${suffix:-""}
	line_width=${line_width:-${RF_LINE_WIDTH:-90}}
	padding_str="${padding_str:-" "}"
	header=${header:-0}
	str=` __blog_replace_tab_by_space "${str}" `

	# check warning, error, info switch and default to color
	if [[ ${warning} -gt 0 ]]; then
		__BLOG_COLORS_RANDOM=$__BLOG_WARNING
		prefix="[WARN] ${prefix}"
	elif [[ ${error} -gt 0 ]]; then	
		__BLOG_COLORS_RANDOM=$__BLOG_ERROR
		prefix="[ERROR] ${prefix}"
	elif [[ ${info} -gt 0 ]]; then
		__BLOG_COLORS_RANDOM=$__BLOG_INFO
		prefix="[INFO] ${prefix}"
	elif [[ ${debug} -gt 0 ]]; then
		__BLOG_COLORS_RANDOM=$__BLOG_DEBUG
		prefix="[DEBUG] ${prefix}"
	#else
		#__blog_random_color_gen
	fi

	local padding=$(( line_width - ${#str} - ${#prefix} - ${#suffix} ))

	__log_debug "prefix: $prefix, suffix: $suffix, line_width: $line_width, padding: $padding"
	
	__blog_repeat --count $padding --prefix "${prefix}${str}" --suffix "${suffix}" "$padding_str"
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
			--header|-hr) __log_debug "got passing from log, so, skip this one";;
			--suffix|-sf) shift; suffix="$1"; __log_debug "got suffix: $1";;
			--prefix|-pf) shift; prefix="$1"; __log_debug "got prefix: $1";;
			--line_width|-lw) shift; line_width="$1"; __log_debug "got line_width: $1";;
			--padding_str|-ps) shift; padding_str="$1"; __log_debug "got padding_str: $1";;
			*) str="$1"; __log_debug "got str: $1";;
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

	str="${prefix} ${str} ${prefix}" # append 2 prefix to str, look like ### header ###
	local padding=$(( line_width - ${#str} - ${#suffix} ))
	
	__log_debug "prefix: $prefix, suffix: $suffix, line_width: $line_width, padding: $padding"

	__blog_repeat --count ${padding} --prefix "${str}" --suffix "${suffix}" "${padding_str}"
}

# log_title create a log have title and content
# log_title [--title "title here" --prefix x --suffix y --line_width numb] "log text here"
# or
# log_title "log text here" [--title "title here" --prefix x --suffix y --line_width numb]
log_title() {
	local title str line_width prefix suffix padding_str ifs
	while [[ $# -gt 0 ]]; do
		case $1 in 
		--title|-t) shift; title="$1"; __log_debug "got title: $1";;
		--suffix|-sf) shift; suffix="$1"; __log_debug "got suffix: $1";;
		--prefix|-pf) shift; prefix="$1"; __log_debug "got prefix: $1";;
		--line_width|-lw) shift; line_width="$1"; __log_debug "got line_width: $1";;
		--padding_str|-ps) shift; padding_str="$1"; __log_debug "got padding_str: $1";;
		--ifs) shift; ifs="$1"; __log_debug "got ifs: $1";;
		*) str="$1"; __log_debug "got str: $1";;
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
		
		# __log_debug "line len: ${#line}, padding: ${padding}"
		
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
		--suffix|-sf) shift; suffix="$1"; __log_debug "got suffix: $1";;
		--prefix|-pf) shift; prefix="$1"; __log_debug "got prefix: $1";;
		--line_width|-lw) shift; line_width="$1"; __log_debug "got line_width: $1";;
		--padding_str|-ps) shift; padding_str="$1"; __log_debug "got padding_str: $1";;
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
		--suffix) shift; suffix="$1"; __log_debug "got suffix: $1";;
		--prefix) shift; prefix="$1"; __log_debug "got prefix: $1";;
		--count) shift; count="$1"; __log_debug "got count: $1";;
		*) str="$1"; __log_debug "got str: $1";;
		esac
		shift
	done
	# check and default values
	count=${count:-${RF_LINE_WIDTH:-90}}
	prefix="${prefix:-}"
	suffix="${suffix:-}"

	local timenow=""
	[[ $__BLOG_TIME -gt 0 ]] && timenow="[`date +"%Y-%m-%d %T"`] "

	# log prefix to stdout and file if any
	echo -en "${__BLOG_COLORS_RANDOM}${timenow}${prefix}"
	[[ -f "${__BLOG_TO_FILE}" ]] && echo -en "${timenow}${prefix}" >> "${__BLOG_TO_FILE}"
	
	# log content to stdout and file if any
	if [[ $count -gt 0 ]]; then
		# range start at 1
		local range=$( seq 1 ${count} )
		for i in $range; do
			echo -n "${str}"
			[[ -f "${__BLOG_TO_FILE}" ]] && echo -n "${str}" >> "${__BLOG_TO_FILE}"
		done
	fi

	# log suffix to stdout and file if any
	# dont use -n to make a new line
	echo -e "${suffix}${__NOCOLOR}"
	[[ -f "${__BLOG_TO_FILE}" ]] && echo -e "${suffix}" >> "${__BLOG_TO_FILE}"
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
