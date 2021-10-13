#!/bin/bash
#The original repo does all this VM id to image id lookup stuff
#...nonsense just give me the image I'll sort out what VM it belongs to 
# (also because I could not easily find that info in the bluestore layout)

id=$1
outpath=$2/
filepath="file_lists/$id.files"
# dd Block Size
bsize=512
# Rados Object size (4MB)
obj_size=4194304

echo $id
echo $filepath
delm="------------------------"
echo $delm
echo "CEPH RECOVERY"
echo "Assemble image with ID $id"
echo $delm
echo "Searching file list"
if [[ ! -e "$filepath" ]]; then
	echo "[ERROR] No files found ($id.files does not exist)"
	exit
fi

echo "$filepath found"
echo $delm
imgfile="$outpath$id.raw"

if [ -f $imgfile ]; then
	echo "Image $imagefile already exists"
	echo "Aborting recovery"
	exit
fi

echo "Output Image will be $imgfile"
echo $delm
count=$(cat $filepath | wc -l)
echo "There are $count blocks found"
#This was an input before? I don't see a reason this can't be just calculated
rbdsize=$(($obj_size * $count))
echo "The output file will be created as a file of size $rbdsize Bytes"
echo "The blocksize is $bsize"
echo $delm
echo "Creating Image file..."
dd if=/dev/zero of=${imgfile} bs=1 count=0 seek=${rbdsize} 2>/dev/null
echo "Starting reassembly..."
curr=1
echo -ne "0%\r"
#LOOP OVER EVERY RBD CHUNK
for i in $(cat $filepath); do
	#this pulls out the hex "counter" that is at the end of every data "name" like rbd_data.id.chunk_id
	ver=$(echo $i | cut -d ":" -f 5 | cut -d "." -f3)
    num=$((16#$ver))
	offset=$(($obj_size * $num / $bsize))
	res=$(dd if=$i of=$imgfile bs=$bsize conv=notrunc seek=${offset} status=none)
	perc=$((($curr*100)/$count))
	#perc=$((($num*obj_size*100)/$rbdsize))
	bar="$perc % ["
	for j in {1..100}; do
		if [ $j -gt $perc ]; then
			bar=$bar"_"
		else
			bar=$bar"#"
		fi
	done
	bar=$bar"] "$curr" of "$count"\r"
	echo -ne $bar
	curr=$(($curr+1))
done
echo -ne "100%"
echo ""
echo "Image written to $imgfile"
