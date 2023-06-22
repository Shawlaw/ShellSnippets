#!/bin/bash

# Get the directory argument
dir=$1

# If no directory argument is provided, use the current directory
if [[ -z $dir ]]; then
  dir=$(pwd)
fi

# Iterate over all files in the directory
for file in "$dir"/*; do
  # Get the filename (without extension)
  withExtFilename=$(basename -- "$file")
  filename="${withExtFilename%.*}"

  # Check if the file is a checksum file
  if [[ $file == *.md5CheckSum || $file == *.sha1CheckSum || $file == *.sha256CheckSum ]]; then
    continue
  fi

  # Check if the checksum files exist
  if [[ ! -f "$dir/$filename.md5CheckSum" || ! -f "$dir/$filename.sha1CheckSum" || ! -f "$dir/$filename.sha256CheckSum" ]]; then
    echo -e "\e[38;5;0m\e[48;5;208mFile $withExtFilename is missing checksum files\e[0m"
    continue
  fi
  
  # Calculate the checksums of the file
  md5=$(md5sum "$file" | awk '{ print $1 }')
  sha1=$(sha1sum "$file" | awk '{ print $1 }')
  sha256=$(sha256sum "$file" | awk '{ print $1 }')

  # Get the checksums from the checksum files
  md5CheckSum=$(cat "$dir/$filename.md5CheckSum")
  sha1CheckSum=$(cat "$dir/$filename.sha1CheckSum")
  sha256CheckSum=$(cat "$dir/$filename.sha256CheckSum")

  # Compare the checksums
  if [[ $md5 == $md5CheckSum && $sha1 == $sha1CheckSum && $sha256 == $sha256CheckSum ]]; then
    echo "File $withExtFilename is OK"
  else
    echo -e "\e[37m\e[41mFile $withExtFilename is corrupted\e[0m"
  fi
done

read -p "Press any key to exit"
