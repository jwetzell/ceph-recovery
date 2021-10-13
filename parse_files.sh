#This file takes the output of collect_files.sh and separates and dedupes it to form the list of files for a specific image
if [ ! -d "file_lists" ]; then
	mkdir "file_lists"
fi
# Sort collected data by Header
echo "Preparing RBD_DATA files"
for l in $(cat files.list.all.tmp | rev | cut -d "/" -f -2 | rev | cut -d ":" -f 5 | cut -d "." -f 2 | sort -u); do
    if [ -f file_lists/$l.files ]; then
        echo "File for id $l exists.... removing before recreating"
	    rm file_lists/$l.files
    fi
    #filter out non rbd_data (this should really be done on the collection stage) and then we only want one unique file
	cat files.list.all.tmp | grep rbd_data | grep $l | sort -k5,5 -t":" -u >> file_lists/$l.files
done
#rm files.list.all.tmp
echo "RBD_DATA files ready"