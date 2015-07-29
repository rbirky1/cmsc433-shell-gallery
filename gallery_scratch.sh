# Template file
#echo $1

# Data file
#echo $2

# Img Source Directory
#echo $3

# Destination Directory
#echo $4

#egrep "^title:" $2 | sed "s/^title://"

#sed "s/^title:\(.*\)$/\1/" $2

egrep "^title:" $2 > /dev/null

if [[ $? -eq 0 ]]; then
	title=$( egrep "^title:" $2 | sed "s/^title://" )
else
	title="My Album"
fi

echo $title

egrep "^description:" $2 > /dev/null

if [[ $? -eq 0 ]]; then
    description=$( egrep "^description:" $2 | sed "s/^description://" )
else
    description=""
fi

echo $description

# Replace title and Description in HTML Template
echo $(sed "s/{{title}}/$title/;s/{{description}}/$description/;" $1) > $3/index.html

# Check if a looping structure exists
start=$(( $(grep -n "^{{#each photos}}" $1 | cut -d ':' -f1) + 1 ))
end=$(( $(grep -n "^{{/each}}" $1 | cut -d ':' -f1) - 1 ))
echo $start
echo $end

# Get code for one image so as to loop for each image and replace the single block
#  with a massive block
photoMarkup=$(sed -n "$start,$end p" $1)
echo $photoMarkup