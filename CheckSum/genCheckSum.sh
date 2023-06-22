#!/bin/bash

# Check the number of arguments
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 targetFile"
  exit 1
fi

# Get the file argument
file=$1

# Get the filename (without extension)
withExtFilename=$(basename -- "$file")
filename="${withExtFilename%.*}"

# Get the directory containing the file
dir=$(dirname -- "$file")

# Calculate the checksums of the file
md5=$(md5sum "$file" | awk '{ print $1 }')
sha1=$(sha1sum "$file" | awk '{ print $1 }')
sha256=$(sha256sum "$file" | awk '{ print $1 }')

echo "file=${withExtFilename}"
echo "md5=${md5}"
echo "sha1=${sha1}"
echo "sha256=${sha256}"

# Write the checksums to the checksum files
echo $md5 > "$dir/$filename.md5CheckSum"
echo $sha1 > "$dir/$filename.sha1CheckSum"
echo $sha256 > "$dir/$filename.sha256CheckSum"

echo "Checksum files have been generated"

read -p "Press any key to exit"

