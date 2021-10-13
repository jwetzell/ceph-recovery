# Ceph Data Recovery
Tested with Ceph BlueStore OSDs

## What these tools are for
These tools are useful to rescue RBD Images stored on Ceph OSDs when everything except the OSDs are lost or broken.
The tools allow you to extract the images from mounted OSDs without any Ceph Service running, so having physical OSDs mounted via network or locally is the only real requirement.

## Requirements
* OSDs must be accessible (filesystem)
* Have enough storage available to save the extracted images
* Patience - some steps need much time (especially since with these method even "empty" image chunks still are copied)
* Screen? You should use screen when using ssh - some steps take multiple hours!

## Steps
To recover the data, two steps are needed:
1. Collect available data (Parts of the images distributed over all OSDs)
2. Reassemble the blocks

## Setup
1. Clone this repo to a place of your choice. Make sure that you have at least a few hundrets MB space in this directory.
2. Create a new subfolder `osds` in this folder.
3. Choose one of the following options or mix them:
3.1. Attach all OSDs as local storage. For every OSD create a subfolder in the `osds` folder and mount it there. Take a look at the docs for [ceph-objectstore-tool]](https://docs.ceph.com/en/pacific/man/8/ceph-objectstore-tool/) with the `fuse` op for easy mounting of local OSDs
3.2.  Use sshfs to mount OSDs over network / ssh


### Check
Your directory structure should look like this:  
```
| ..
| .
| straight-assamble.sh
| collect_files.sh
| parse_files.sh
+- osds
 +- osd1
 +- osd2
 +- .......
```

## Step 1: Collect and parse files
Quite easy:  
`./collect_files.sh <base_osd_dir>` in our example file structure this would be `./collect_files.sh ./osds` 

This could take a bit longer. Depends on your mount strategy (local vs sshfs) and your network.

You will ultimately end up with a `files.list.all.tmp` file which contains all found files of interest.

`./parse_files.sh` will take this file and chunk it up by rbd image id deduplicating along the way.

## Step 2: Recover Image
Now we have everything to reassemble an image. The parts belonging to a specific Image are known and listed in files stored in `file_lists`.  
To restore an image you need **3** information:
1. The id of the Image this is the part of the file name before `.files` in `file_lists/`
2. A destination folder. Just a folder with enough free space to store your image of the specified size. (e.g. `/mnt/sda`)

Having these 3 information you can restore the image:  
`./assemble.sh vms/vm-xyz-disk-n.id 34359738368 /mnt/sda`

This will process all parts of the image and write it to a single image file. After this you can mount this image and access data or just put it back to a new cluster. 

**Repeat this for every disk image you need**.