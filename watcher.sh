#!/bin/bash
echo"Hi, thanks for using the script! Running now..."

#This script is most certainly still in dev and should not be taken seriously. 

#Colors :3
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
output_file=""

# Parse command line options?
while getopts ":vo:" opt; do
  case ${opt} in
    v ) verbose=true ;;
#    o ) output_file="$OPTARG" ;;
    \? ) echo "Invalid option: $OPTARG" 1>&2 ;;
#    : ) echo "Option -$OPTARG requires an argument" 1>&2 ;;
  esac
done
shift $((OPTIND -1))

# Access the flag values
echo "Verbose mode: $verbose"
#echo "Output file: $output_file"


# Define the output JSON file
output_file="$HOME/json_output.log"

# Set GOPATH and update PATH
export GOPATH=$HOME/go
export GOROOT=/usr/local/go  # Assuming this is the location of your Go installation
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

# Start converting logs to JSON in the background
echo "Recording data and converting..."
while true; do
    # Read each line from htb-cli shoutbox command and process it
    htb-cli shoutbox | while IFS= read -r log_entry; do
        # Extracting timestamp
        timestamp=$(echo "$log_entry" | sed 's/[][]//g' | awk '{print $1, $2, $3}')

        # Extracting username
        username=$(echo "$log_entry" | awk -F ' - ' '{print $2}' | awk '{print $1}')

        # Extracting flag type
        flag_type=$(echo "$log_entry" | awk -F 'owned ' '{print $2}' | awk '{print $1}' | tr -d "'")

        # Extracting box
        box=$(echo "$log_entry" | awk -F 'on ' '{print $2}' | awk '{print $1}')

        # Construct JSON object
        json="{\"timestamp\":\"$timestamp\", \"username\":\"$username\", \"flag type\":\"$flag_type\", \"box\":\"$box\"}"

        # Output the JSON object
        echo -e "${GREEN}JSON object:${NC} $json"

        # Check if the JSON object already exists in the file
        if grep -qF "$username" "$output_file"; then
        echo "ugh"
            # Get the current timestamp
            current_timestamp=$(date +%s)
			echo "$current_timestamp"
            # Check each line in the output file for similar user within one hour
            while IFS= read -r line; do
                # Extract username from the line
                line_username=$(echo "$line" | grep -oP '"username":"\K[^"]+')
				
                    # Extract timestamp from the line
                    echo "check"
                    line_timestamp=$(echo "$line" | grep -oP '"timestamp":"\K[^"]+')
					
                    # Convert timestamp to seconds since epoch
                    line_timestamp_seconds=$(date -d "$line_timestamp" +%s)
					echo "$line_timestamp_seconds"
                    # Calculate the time difference in seconds
                    time_diff=$((current_timestamp - line_timestamp_seconds))
					echo "$time_diff"
                    # If time difference is less than one hour (3600 seconds), change the color of the line to yellow
                    if [ "$time_diff" -lt 3600 ]; then
                    	echo "what?"
                        # Replace the line with yellow color
                        sed -i "s@$line@$YELLOW$line$NC@g" "$output_file"
                        echo "Flagged line: $line"
                    fi

                # Assign the current username as previous username for the next iteration
                prev_username="$line_username"
            done < "$output_file"
        fi

        # Append JSON object to the output file
        echo "$json" >> "$output_file"
    done
done


