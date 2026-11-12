#!/usr/bin/env bash
# dysk.sh - script to monitor disk space usage
set -euo pipefail

THRESHOLD_PERCENT=85
VERBOSE_MODE=0

# help function, $0 keeps scirpt path from where is executed

print_usage() {
    cat <<EOF
Usage: $0 [-p PERCENT] [-v] [-h]

Checks disk usage of mounted filesystem (tmpfs)  and prints a warning
if usage reaches or exceeds the threshold (default: 85%).

Options:
  -p PERCENT  Usage threshold in percent (0-100). Default: 85
  -v          Verbose mode: also print filesystems below threshold
  -h          Show this help message and exit
EOF
}

# using while loop and getops tool to controll input parameters 
# p: - it means that p requires a value
# v - it means that when we enter this flag, VERBOSE_MODE from default 0, will update to 1
# \? - any other letter/flag - display help and forward stderr for code 2 = invalid argument

while getopts "p:vh" option; do
    case "$option" in
        p)
            THRESHOLD_PERCENT="$OPTARG"
            ;;
        v)
            VERBOSE_MODE=1
            ;;
        h)
            print_usage
            exit 0
            ;;
        \?)
            print_usage >&2
            exit 2
            ;;
    esac
done

# validate that THRESHOLD_PERCENT is an integer between 0 and 100
if [[ ! "$THRESHOLD_PERCENT" =~ ^[0-9]+$ ]] || [ "$THRESHOLD_PERCENT" -gt 100 ]; then
    echo "Error: PERCENT must be an integer between 0 and 100." >&2
    exit 2
fi

EXIT_STATUS=0

# df -P uses POSIX format (always 6 columns).
# tail -n +2 skips the first line (the table header).
# underscores _ ignore 3 columns; MOUNT_POINT captures the path
# read - r allow for raw mode - \ sign within the path will not cause any problems

while read -r FILESYSTEM_NAME _ _ _ CAPACITY_TEXT MOUNT_POINT; do
    # Remove '%' character
    USAGE_PERCENT="${CAPACITY_TEXT%\%}"

    if [ "$USAGE_PERCENT" -ge "$THRESHOLD_PERCENT" ]; then
        echo "WARNING: Filesystem $MOUNT_POINT ($FILESYSTEM_NAME) is ${USAGE_PERCENT}% full (threshold: ${THRESHOLD_PERCENT}%)" >&2
        EXIT_STATUS=1
    elif [ "$VERBOSE_MODE" -eq 1 ]; then
        echo "OK: Filesystem $MOUNT_POINT ($FILESYSTEM_NAME) is ${USAGE_PERCENT}% full (threshold: ${THRESHOLD_PERCENT}%)"
    fi
done < <(df -P -x tmpfs | tail -n +2) #source of data for while loop

exit "$EXIT_STATUS"
