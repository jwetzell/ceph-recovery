#!/bin/bash

OSDDIR=$1

if [ -f "files.list.all.tmp" ]; then
	echo "Clearing old .tmp file list"
	rm files.list.all.tmp
fi

# Loop all OSDs
for x in $(ls $OSDDIR); do
	echo Scanning $x
	# SEARCH ALL _head directories
	for y in $(find $OSDDIR/$x -maxdepth 1 -type d | grep _head); do
		echo Searching for data in $y
		#locate any data files that actually have a size (this could realistically be set to exact size match the RBD block size)
		find $y -maxdepth 4 -type f -name data -size +1b >> files.list.all.tmp
		#find $y -name *id* >> vms.list.all.tmp
	done
done

