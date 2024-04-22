#!/bin/bash

path="/root"
sourceFolderPath="$path/input_data" # Set the source folder path here
targetFolderPath="$path/shared_with_realm" # Set the target folder path here
stateFilePath="$path/shared_with_realm/signalling.txt" # Use a .txt file for state and file name

# Initialize the state file with 'processed' state
rm -f "$targetFolderPath"/*.bmp                                                       
echo "systemState: processed" > "$stateFilePath"
echo "fileName: " >> "$stateFilePath"

for bmpFile in "$sourceFolderPath"/*.bmp; do
    if [[ -f "$bmpFile" ]]; then
        systemState=$(grep 'systemState' "$stateFilePath" | awk '{print $2}')

        while true; do
            if [[ "$systemState" == "processed" ]]; then
                break
            fi
            sleep 5
            systemState=$(grep 'systemState' "$stateFilePath" | awk '{print $2}') # Refresh state
        done
	echo "Current systemState: $systemState"
        # Copy the bmp file to the target folder
        cp "$bmpFile" "$targetFolderPath/"
        echo "Copied $bmpFile to $targetFolderPath/"

        # Prepare the new fileName value
        newFileName="$targetFolderPath/$(basename "$bmpFile")"
	
        # Update the systemState and fileName in the state file
        
        echo "systemState: query" > "$stateFilePath"
        echo "fileName: $newFileName" >> "$stateFilePath"
	echo "System state updated to 'query' and fileName to $newFileName"
    fi
done
echo "systemState: finished............................" > "$stateFilePath"
