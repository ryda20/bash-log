#!/bin/bash

echo "term: $TERM"

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

# export for another use
export __BLOG_DEBUG_ENABLED=0

__BLOG_ERROR=$__RED
__BLOG_INFO=$__GREEN
__BLOG_WARNING=$__YELLOW
__BLOG_DEBUG=$__MAGENTA

# replace tab with 2 spaces, different to 2, will replace with 4 spaces
__BLOG_REPLACE_TAB_BY_SPACE=2

# the file path to save log
__BLOG_TO_FILE=""
log_to() {
	__BLOG_TO_FILE=${1:-""}
	[[ -z "$__BLOG_TO_FILE" ]] && return

	local dir=`dirname "$__BLOG_TO_FILE"`
	mkdir -p "$dir"
	touch "$__BLOG_TO_FILE"
}

# log with time as prefix
__BLOG_TIME=1
__BLOG_TIME_SKIP=0 # temporary skip time prefix, skip when -gt 0
log_time() {
	__BLOG_TIME=${1:-1}
}

# log with caller function name as prefx. 1 Enable, 0 Disable
__BLOG_CALLER_FN_NAME=0
__BLOG_CALLER_FN_DEPTH=2
__BLOG_CALLER_FN_SKIP=0 # temporary skip caller
log_fn_name() {
	local callerEnable="${1:0}" # default to disable
	local callerDepth="${2:-1}" # default to 1
	__BLOG_CALLER_FN_NAME=$callerEnable
	__BLOG_CALLER_FN_DEPTH=$callerDepth
}

logd() {
	log_debug "$@"
}
__log_debug() {
	log_debug "$@"
}
# log_debug internal debug log
log_debug() {
	local force=""
	local args=()
	while [[ $# -gt 0 ]]; do
		case $1 in
			--debug|--dev)
				force="yes" # enable debug log, this variable from bashlog package
				;;
			*)
				# save $1 to args array
				args=("${args[@]}" "$1")
		esac
		shift
	done 

	# show log only when have log_debug.txt file or __BLOG_DEBUG_ENABLED env is greater than 0
	if [[ -f "debug.txt" || $__BLOG_DEBUG_ENABLED -gt 0 || "$force" == "yes" ]]; then
		log --debug "${args[@]}"
	fi
}

__blog_replace_tab_by_space() {
	if [[ "$__BLOG_REPLACE_TAB_BY_SPACE" == "2" ]]; then
		echo -e "${1}" | sed 's/\t/  /g'
	else
		# replace tab with 4 spaces
		echo -e "${1}" | sed 's/\t/    /g'
	fi
}

# replace <b></b> with bold code \e[1m \e[21m
# replace <i></i> with italic code \e[3m \e[23m
# replace <u></u> with underline code \e[4m \e[24m
# replace <s></s> with strikethrough code \e[9m \e[29m
# https://misc.flogisoft.com/bash/tip_colors_and_formatting
# 0 - Normal Style
# 1 - Bold
# 2 - Dim
# 3 - Italic
# 4 - Underlined
# 5 - Blinking
# 7 - Reverse
# 8 - Invisible - hidden
# 9 - strikethrought
# Note:
# 2 is for dim color, not disabling bold. 
# 22 is for disabling dim and bold. 
# Disabling bold with 21 is not widely supported (e.g. no support on macOS)
#
__blog_text_style() {
	local str="$1"
	# note: for now, i just know this code work on Linux
	# does not work on MacOS, just remove formating tag
	if [[ "$(uname -a)" == *"Darwin"* ]]; then
		str=$( echo $str | sed \
			-e 's%<b>%%g' -e 's%</b>%%g' \
			-e 's%<d>%%g' -e 's%</d>%%g' \
			-e 's%<i>%%g' -e 's%</i>%%g' \
			-e 's%<u>%%g' -e 's%</u>%%g' \
			-e 's%<blink>%%g' -e 's%</blink>%%g' \
			-e 's%<r>%%g' -e 's%</r>%%g' \
			-e 's%<h>%%g' -e 's%</h>%%g' \
			-e 's%<s>%%g' -e 's%</s>%%g' \
		)
	else
		str=$( echo $str | sed \
			-e 's%<b>%\\e[1m%g' -e 's%</b>%\\e[22m%g' \
			-e 's%<d>%\\e[2m%g' -e 's%</d>%\\e[22m%g' \
			-e 's%<i>%\\e[3m%g' -e 's%</i>%\\e[23m%g' \
			-e 's%<u>%\\e[4m%g' -e 's%</u>%\\e[24m%g' \
			-e 's%<blink>%\\e[5m%g' -e 's%</blink>%\\e[25m%g' \
			-e 's%<r>%\\e[7m%g' -e 's%</r>%\\e[27m%g' \
			-e 's%<h>%\\e[8m%g' -e 's%</h>%\\e[28m%g' \
			-e 's%<s>%\\e[9m%g' -e 's%</s>%\\e[29m%g' \
		)
	fi
	echo "$str"
}


__blog_number_of_match() {
	local str="$1"
	local replace="$2"
	local match=$(echo "$str" | grep -o "$replace" | wc -l)
	echo ${match:-0}
}
__blog_text_match_count() {
	local str="$1"
	local count=0

	# how many html tag need to replace on this str?
	# note: grep have -c option to count matching but it only count in multiline,
	#		if one line have two or more, it just calculate as 1
	# that is reason, we use wc with -l (line count) option after 
	#	grep -o (print out match only, each match per line)
	#
	# local countx=0
	# countx=$(echo "$str" | grep -o "<b>" | wc -l)
	# count=$(( $count + $countx ))
	# countx=$(echo "$str" | grep -o "<d>" | wc -l)
	# count=$(( $count + $countx ))
	# countx=$(echo "$str" | grep -o "<i>" | wc -l)
	# count=$(( $count + $countx ))
	# countx=$(echo "$str" | grep -o "<u>" | wc -l)
	# count=$(( $count + $countx ))
	# countx=$(echo "$str" | grep -o "<blink>" | wc -l)
	# count=$(( $count + $countx ))
	# countx=$(echo "$str" | grep -o "<r>" | wc -l)
	# count=$(( $count + $countx ))
	# countx=$(echo "$str" | grep -o "<h>" | wc -l)
	# count=$(( $count + $countx ))
	# countx=$(echo "$str" | grep -o "<s>" | wc -l)
	# count=$(( $count + $countx ))
	count=$(( $count + $(echo "$str" | grep -o "<b>" | wc -l) ))
	count=$(( $count + $(echo "$str" | grep -o "<d>" | wc -l) ))
	count=$(( $count + $(echo "$str" | grep -o "<i>" | wc -l) ))
	count=$(( $count + $(echo "$str" | grep -o "<u>" | wc -l) ))
	count=$(( $count + $(echo "$str" | grep -o "<blink>" | wc -l) ))
	count=$(( $count + $(echo "$str" | grep -o "<r>" | wc -l) ))
	count=$(( $count + $(echo "$str" | grep -o "<h>" | wc -l) ))
	count=$(( $count + $(echo "$str" | grep -o "<s>" | wc -l) ))
	# count=$(( $count + __blog_number_of_match "$str" "<b>" ))
	# count=$(( $count + __blog_number_of_match "$str" "<d>" ))
	# count=$(( $count + __blog_number_of_match "$str" "<i>" ))
	# count=$(( $count + __blog_number_of_match "$str" "<u>" ))
	# count=$(( $count + __blog_number_of_match "$str" "<blink>" ))
	# count=$(( $count + __blog_number_of_match "$str" "<r>" ))
	# count=$(( $count + __blog_number_of_match "$str" "<h>" ))
	# count=$(( $count + __blog_number_of_match "$str" "<s>" ))
	echo "$count"
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
	local str=""
	local prefix="# "
	local suffix=""
	local line_width=${RF_LINE_WIDTH:-90}
	local padding_str=" "
	local previous_color=$__BLOG_COLORS_RANDOM
	#
	while [[ $# -gt 0 ]]; do
		case $1 in 
		--warning|--warn)
			__BLOG_COLORS_RANDOM=$__BLOG_WARNING
			prefix="${prefix}[WARN] "
			;;
		--error)
			__BLOG_COLORS_RANDOM=$__BLOG_ERROR
			prefix="${prefix}[ERROR] "
			;;
		--info)
			__BLOG_COLORS_RANDOM=$__BLOG_INFO
			prefix="${prefix}[INFO] "
			;;
		--debug)
			__BLOG_COLORS_RANDOM=$__BLOG_DEBUG
			prefix="${prefix}[DEBUG] "
			;;
		--end|-ed)
			log_end "${args[@]}"
			return;;
		--empty|-e)
			log_empty "${args[@]}"
			return;;
		--step|-s)
			log_step "${args[@]}"
			return;;
		--header|-h)
			log_header "${args[@]}"
			return;;
		--title|-t)
			log_title "${args[@]}"
			return;;
		--suffix|-sf)
			shift; suffix="$1"; log_debug "got suffix: $1";;
		--prefix|-pf)
			shift; prefix="$1"; log_debug "got prefix: $1";;
		--line_width|-lw)
			shift; line_width="$1"; log_debug "got line_width: $1";;
		--padding_str|-p)
			shift; padding_str="$1"; log_debug "got padding_str: $1";;
		--depth|-d)
			shift; __BLOG_CALLER_FN_DEPTH=$1; log_debug "got caller depth: $1";;
		--skip-caller-name)
			__BLOG_CALLER_FN_SKIP=1; log_debug "got --skip-caller-name option";;
		--skip-time)
			__BLOG_TIME_SKIP=1; log_debug "got --skip-time option";;
		--cmd)
			prefix="<i>\$"
			suffix="</i>"
			;;
		*)
			# append all other parameter to arrstr
			str="$str $1"; log_debug "got str: $1";;
		esac
		shift
	done

	# replace tab by space
	str=`__blog_replace_tab_by_space "$str"`
	# replace some 'html' text style with shell color/style code
	str=$(__blog_text_style "$str")
	prefix=$(__blog_text_style "$prefix")
	suffix=$(__blog_text_style "$suffix")

	local padding=$(( line_width - ${#str} - ${#prefix} - ${#suffix} ))

	log_debug "prefix: $prefix, suffix: $suffix, line_width: $line_width, padding: $padding"
	
	__blog_repeat --count $padding --prefix "${prefix} " --suffix "${suffix}" --padding_str "$padding_str" "${str}"

	# re-set log color to previous time (for case it changed in ERROR, INFO, WARNING)
	__BLOG_COLORS_RANDOM=$previous_color
}

# log_header log text as header
# allow to change line_width
# log_header [--prefix x --suffix y --line_width numb] "log text here"
# or
# log_header "log text here" [--prefix x --suffix y --line_width numb]
# no support another text style except bold
log_header() {
	local str line_width prefix suffix padding_str
	local bold_header=yes

	while [[ $# -gt 0 ]]; do
		case $1 in 
			# must to check --header | -h because we pass all agruments from caller
			--header|-h) log_debug "got passing from log, so, skip this one";;
			--suffix|-sf) shift; suffix="$1"; log_debug "got suffix: $1";;
			--prefix|-pf) shift; prefix="$1"; log_debug "got prefix: $1";;
			--line_width|-lw) shift; line_width="$1"; log_debug "got line_width: $1";;
			--padding_str|-ps) shift; padding_str="$1"; log_debug "got padding_str: $1";;
			--no-bold) bold_header=no; log_debug "no bold header";;
			*) str="$1"; log_debug "got str: $1";;
		esac
		shift
	done
	# check and set default values
	prefix="${prefix:-"####"}"
	suffix="${suffix:-"#"}"
	line_width=${line_width:-${RF_LINE_WIDTH:-90}}
	padding_str="${padding_str:-"="}"

	# replace tab by space
	str=` __blog_replace_tab_by_space "${str}" `
	# replace some 'html' text style with shell color/style code
	str=$(__blog_text_style "$str")
	prefix=$(__blog_text_style "$prefix")
	suffix=$(__blog_text_style "$suffix")


	# make header bold as default -> line_width must be change too (+11 chars)
	# and only on linux
	if [[ "$bold_header" == "yes" && "$(uname -a)" == *"Linux"* ]]; then
		str="\e[1m$str\e[22m"
		line_width=$(( $line_width + 11 ))
	fi

	__blog_random_color_gen

	
	str="${prefix} ${str} ${prefix}" # append 2 prefix to str, look like ### header ###
	local padding=$(( line_width - ${#str} - ${#suffix} ))
	
	log_debug "prefix: $prefix, suffix: $suffix, line_width: $line_width, padding: $padding"

	__blog_repeat --count ${padding} --prefix "${str}" --suffix "${suffix}" --padding_str "${padding_str}" ""
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

	# re-calculate line_width with prefix and suffix
	line_width=$(( $line_width + ${#prefix} + ${#suffix} ))

	# str=` __blog_replace_tab_by_space "${str}" `
	# # replace some 'html' text style with shell color/style code
	# str=$(__blog_text_style "$str")

	ifs=${ifs:-$'\n'}
	local padding=0

	# print out header
	log_header "${title}" --line_width ${line_width}
	
	local saveIFS="$IFS" && IFS=$ifs
	for line in ${str}; do
		
		line="$( __blog_replace_tab_by_space "${line}" )"
		match_count=$( __blog_text_match_count "$line" ) # count matche number before replace
		line=$(__blog_text_style "$line") # replace some 'html' text style with shell color/style code
		
		# for i,b,... text syle - those character does not display on page
		# but still count on length, so, we much to increase more padding
		# when using those style. Each match will count 11 chars (\e[1m and \e[xxm)
		#
		padding=$(( $line_width - ${#line} - ${#prefix} - ${#suffix} + $match_count * 11 ))
		
		log_debug "line_width: ${line_width}, line_len: ${#line}, padding: ${padding}"
		
		[[ $padding -lt 1 ]] && padding=0
		__blog_repeat --count ${padding} --prefix "${prefix}" --suffix "${suffix}" --padding_str "${padding_str}" ${line}
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
	local str="" # not have any str to print out
	__blog_repeat --count ${padding} --prefix "${prefix}" --suffix "${suffix}" --padding_str "${padding_str}" ${str}
	# echo # make new line
}

log_empty(){
	__BLOG_TIME_SKIP=1
	__BLOG_CALLER_FN_SKIP=1
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

# __blog_repeat will printout prefix, str, suffix and padding_str (fill out full linewidth)
# it repeat padding_str char N times until come to linewidth value
__blog_repeat() {
	local str padding_str count prefix suffix
	while [[ $# -gt 0 ]]; do
		case $1 in 
		--suffix) shift; suffix="$1"; log_debug "got suffix: $1";;
		--prefix) shift; prefix="$1"; log_debug "got prefix: $1";;
		--count) shift; count="$1"; log_debug "got count: $1";;
		--padding_str) shift; padding_str="$1"; log_debug "got padding str: \"$1\"";;
		*) str="$1"; log_debug "got str: $1";;
		esac
		shift
	done
	# check and default values
	count=${count:-${RF_LINE_WIDTH:-90}}
	prefix="${prefix:-}"
	suffix="${suffix:-}"
	
	local timenow=""
	[[ $__BLOG_TIME -gt 0 && $__BLOG_TIME_SKIP -eq 0 ]] && timenow="[`date +"%Y-%m-%d %T"`] "
	__BLOG_TIME_SKIP=0 # reset

	local callerName=""
	if [[ $__BLOG_CALLER_FN_NAME -gt 0 && $__BLOG_CALLER_FN_SKIP -eq 0 ]]; then
		local caller=($(caller $__BLOG_CALLER_FN_DEPTH))
		callerName="[${caller[1]}] "
	fi
	__BLOG_CALLER_FN_SKIP=0 # reset

	# log prefix to stdout and file if any
	echo -en "${__BLOG_COLORS_RANDOM}${timenow}${prefix}${callerName}${str}"
	[[ -f "${__BLOG_TO_FILE}" ]] && echo -en "${timenow}${prefix}${callerName}${str}" >> "${__BLOG_TO_FILE}"
	
	# check and printout padding_str
	if [[ $count -gt 0 ]]; then
		# range start at 1
		local range=$( seq 1 ${count} )
		for i in $range; do
			echo -en "${padding_str}"
			[[ -f "${__BLOG_TO_FILE}" ]] && echo -en "${padding_str}" >> "${__BLOG_TO_FILE}"
		done
	fi

	# log suffix to stdout and file if any
	# dont use -n to make a new line
	echo -e "${suffix}${__NOCOLOR}"
	[[ -f "${__BLOG_TO_FILE}" ]] && echo -e "${suffix}" >> "${__BLOG_TO_FILE}"

	# rest __BLOG_COLORS_RANDOM
	# __blog_random_color_gen
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
