#!/bin/bash
# Function to handle cleanup before exiting
cleanup() {
    echo -e "\nExiting..."
    exit 0
}

# Trap Ctrl+C signal to call the cleanup function
trap cleanup SIGINT

echo "Hi, thanks for using the script! Running now..."

# Colors :3
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Initialize variables with default values
verbose=false
output_file="${PWD}/json_output.log"

# Set GOPATH and update PATH
export GOPATH=$HOME/go
export GOROOT=/usr/local/go  # Assuming this is the location of your Go installation
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

# Function to update the color of a line in the output file to yellow if it occurred within the last hour
update_line_color() {
    local line="$1"
    sed -i "s@$line@$YELLOW$line$NC@g" "$output_file"
    echo -e "${PURPLE}Flagged line: $line${NC}"
}

# Start converting logs to JSON in the background
echo "Recording data and converting..."
declare -A user_last_occurrence  # Associative array to track the most recent occurrence of each user

while true; do
    # Read each line from htb-cli shoutbox command and process it
    htb-cli shoutbox | while IFS= read -r log_entry; do
        # Extracting timestamp
        timestamp=$(echo "$log_entry" | sed 's/[][]//g' | awk '{print $1, $2, $3}')

        # Extracting username
        username=$(echo "$log_entry" | awk -F ' - ' '{print $2}' | awk '{print $1}')

        # Extracting flag type
        flag_type=$(echo "$log_entry" | awk -F 'owned ' '{print $2}' | awk '{print $1}' | tr -d "'")

        # Extracting box (including spaces)
        box=$(echo "$log_entry" | awk -F ' on ' '{for (i=2; i<=NF; i++) printf "%s ", $i}' | sed 's/^[ \t]*//;s/[ \t]*$//')

        # Construct JSON object
        json="{\"timestamp\":\"$timestamp\", \"username\":\"$username\", \"flag type\":\"$flag_type\", \"box\":\"$box\"}"

        # Output the JSON object
        echo -e "${GREEN}JSON object:${NC} $json"

        # Get the current timestamp
        current_timestamp=$(date +%s)

        # Check if the log entry indicates a solved challenge
        if echo "$log_entry" | grep -q "solved challenge"; then
            # Extracting challenge name and category
            challenge_name=$(echo "$log_entry" | grep -oP 'solved challenge \K.*(?= from)')
            challenge_category=$(echo "$log_entry" | grep -oP 'from \K.*$')

            # Construct JSON object for solved challenge
            json="{\"timestamp\":\"$timestamp\", \"username\":\"$username\", \"challenge name\":\"$challenge_name\", \"challenge category\":\"$challenge_category\"}"

            # Output the JSON object for solved challenge
            echo -e "${GREEN}JSON object:${NC} $json"

            # Append JSON object to the output file for solved challenge
            echo "$json" >> "$output_file"
        fi

        # Check if the user's last occurrence timestamp is within the last hour
        if [ -n "${user_last_occurrence[$username]}" ]; then
            time_diff=$((current_timestamp - ${user_last_occurrence[$username]}))
            if [ "$time_diff" -lt 3600 ]; then
                update_line_color "$json"
            fi
        fi

        # Update the user's last occurrence timestamp
        user_last_occurrence[$username]=$current_timestamp

        # Append JSON object to the output file
        echo "$json" >> "$output_file"
    done
done
