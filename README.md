bashlog is a small script to make to output message with color support

Download to your current project and use

```sh
wget -O log.sh https://raw.githubusercontent.com/ryda20/bashlog/master/log.sh
```

Or Using directly:

```sh
source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/ryda20/bashlog/master/log.sh)"

```

Functions:

```sh
# log_to saves all log to file_path
# default is empty - log to stdout
log_to [file_path]


# log_time enables log date-time as prefix
# default is 1
log_time [1 or 0]


# log prints out log
#  options:
#  --prefix|-pf "prefix_value"  => set prefix value
#  --suffix|-sf "suffix value"  => set suffix value
#  --line_width|-lw 100   => change line width value
#  --padding_str|-p "value"  => change padding string
#  --header|-h    => make a header log (call log_header from log function)
#  --title|-t    => make a title log (call log_title from log function)
#  --empty|-e    => make a empty log line (call log_empty from log function)
#  --end|-ed    => make a end log line (call log_end_from log function)
#  --error    => make a error log message (red message) with prefix ERROR
#  --warning    => make a warning log message (yellow message) with prefix WARN
#  --info     => make a info log message (green message) with prefix INFO
log [options] message
```
