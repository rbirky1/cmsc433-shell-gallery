#!/bin/bash

# Validate Command Line Arguments
if [[ $# -ne 4 ]]; then printf "Illegal number of parameters.\n" >&2; exit 1; fi

if [[ ! -f "$1" ]]; then printf "Template file does not exits.\n" >&2; exit 1; fi

if [[ ! -f "$2" ]]; then printf "Metadata file does not exist.\n" >&2; exit 1; fi

if [[ ! -d "$3" ]]; then printf "Images directory does not exist.\n" >&2; exit 1; fi

# Check for existing destination directory
if [[ -d "$4" ]]
then
    read -r -p "Directory exists. Overwrite? (Y/N): " overwrite
    while [[ $overwrite != "Y" && $overwrite != "y" && $overwrite != "N" && $overwrite != "n" ]]
    do
	read -r -p "Invalid option. Type Y or N: " overwrite
    done
    if [[ $overwrite = "Y" || $overwrite = "y" ]]; then
        rm -rf "$4"
        mkdir "$4"
    fi
else
    mkdir "$4"
fi

# Set up directories
thumbDest="/thumbs"
thumbDestPath="$4$thumbDest"
mkdir "$thumbDestPath"
imgDest="/imgs"
imgDestPath="$4$imgDest"
mkdir "$imgDestPath"

# Get Album Title
egrep "^title:" $2 > /dev/null

if [[ $? -eq 0 ]]; then
    title=$( egrep "^title:" $2 | sed "s/^title://" )
else
    title="My Album"
fi

# Get Album Description
egrep "^description:" $2 > /dev/null

if [[ $? -eq 0 ]]; then
    description=$( egrep "^description:" $2 | sed "s/^description://" )
else
    description=""
fi

# Replace title and Description in HTML Template
echo "$(sed "s/{{title}}/$title/;s/{{description}}/$description/;" $1)" > "$4/index.html"

# Check if a looping structure exists
start=$(( $(grep -n "^{{#each photos}}" $1 | cut -d ':' -f1) + 1 ))
end=$(( $(grep -n "^{{/each}}" $1 | cut -d ':' -f1) - 1 ))

# Get code for one image so as to loop for each image and replace the single block
#  with a massive block
echo "$(sed -n "$start,$end p" $1)" > "$4/photoMarkup"

# Temp file
echo "" > $4/temp

# Make Thumbnails and Code Blocks
imgs=$( find "$3" -iname "*.jpg" -o -iname "*.jpeg" )
for img in $imgs
do
    cp $img $imgDestPath
    imgName="${img##*/}"
    echo "Creating thumbnail for $imgName"

    imgNameOnly=$(echo $imgName | cut -d'.' --complement -f2-)
    thumbName=$imgNameOnly-thumb.jpg
    thumbPath=$thumbDestPath/$thumbName

    convert -thumbnail 100x100^ \
	   -gravity center -extent 100x100 \
	$img $thumbPath

    # Find corresponding data in pics.dat
    egrep "^$imgName:" $2 > /dev/null

    if [[ $? -eq 0 ]]; then
        thisCaption=$( egrep "^$imgName:" $2 | sed "s/^$imgName://" )
    else
        thisCaption=""
    fi

    href="$imgDest/$imgName"
    src="$thumbDest/$thumbName"
    # Replace data in photoMarkup and append to temp
    sed "s;{{full}};$href;;s;{{caption}};$thisCaption;g;s;{{thumb}};$src;;" $4/photoMarkup >> $4/temp
done

echo "Generating HTML"

insertText=$(echo $(cat $4/temp))

start=$((start-1))
end=$((end+1))

# Delete former code on lines 42-46 (start-end)
sed -i "$start, $end d" "$4/index.html"

# Insert new code
sed -i "${start}i\
$insertText" "$4/index.html"

# Delete temp files
rm "$4/photoMarkup"
rm "$4/temp"

exit 0