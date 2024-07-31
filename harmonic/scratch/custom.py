```
#!/usr/bin/env python3
####
#
#  Program: 42-custom-disk-layout.sh
#
#  Description:
#  This python script is to specify how to select and partition a disk in MAAS.
#  Inputs: the MAAS_RESOURCES_FILE from previous default scripts is a json
# construct detailing the hardware that is currently being "commissioned".
#  Outputs: the MAAS_STORAGE_CONFIG_FILE should contain a json structure
# that defines the selected hard disk and where to slice it up to the standard
# mountpoints for the OS installation, however that step continually failed.
# Instead this script loads all the data from the MAAS_RESOURCES_FILE, then
# adds the ['storage-extra'] block with the selected disk, partitions, and
# logical volumes.
#
#  Programmer:	Charles Bedford
#  History:
#    2022-09-30 - CHB - Initial revision
#
# --- Start MAAS 1.0 script metadata ---
# name: 42-custom-disk-layout
# title: Set layout for DELL Virtual disks
# description: Set layout for DELL Virtual disks
# script_type: commissioning
# timeout: 60
# --- End MAAS 1.0 script metadata ---
#
####
import json
import os
import sys

# Function definitions
def read_json_file(path):
    try:
        with open(path) as fd:
            return json.load(fd)
    except OSError as e:
        sys.exit(f"Failed to read {path}: {e}")
    except json.JSONDecodeError as e:
        sys.exit(f"Failed to parse {path}: {e}")

# Load the hardware from the json in the MAAS_RESOURCES_FILE
hardware = read_json_file(os.environ['MAAS_RESOURCES_FILE'])

####
#
#  This is the primary datastructure (in json format) with
# placeholders which are easily found and replaced below (DISK & MAX)
#
####
cfg = '''{
    "layout": {
        "DISK": {
            "type": "disk",
            "ptable": "gpt",
            "boot": true,
            "partitions": [
                { "name": "DISK1", "fs": "fat32", "size": "2G", "bootable": true },
                { "name": "DISK2", "size": "MAX" }
            ]
        },
        "vg": {
            "type": "lvm",
            "members": [ "DISK2" ],
            "volumes": [
                { "name": "lv1", "size": "100G", "fs": "ext4" },
                { "name": "lv2", "size": "16G", "fs": "swap" },
                { "name": "lv3", "size": "220G", "fs": "ext4" }
               
            ]
        }
    },
    "mounts": {
        "/": { "device": "lv1" },
        "/boot/efi": { "device": "DISK1" }, 
        "none": { "device": "lv2" },
        "/data": { "device": "lv3" }
        
    }
}'''

disks = hardware['resources']['storage']['disks']

# Initialize a few variables so we have consistent values below
primary = ''
primaryId = 0
diskSize = 0
index=0

# Iterate through all the disks defined for this machine
for disk in disks:
    # skip virtual mounted drives from maas
    if 'Virtual' in disk["model"] or 'Virtual' in disk['device_id']:
        continue

    # find the PERC or DELLBOSS id to use...
    if 'PERC' in disk["model"] or 'DELLBOSS' in disk["model"]:
            primary = disk['id']
            primaryId = index
            diskSize = disk['size']

    index+=1

# if the loop didn't find a PERC or DELLBOSS drive to use
# barring that it will have to be #0
if primary == '':
    primary=disks[0]['id']
    primaryId = 0
    diskSize = disks[0]['size']

# The disk ID (sda or whatever) that we want to use for booting...
diskId = hardware["resources"]["storage"]["disks"][primaryId]["id"]

# Load layoutDetail from the above structure
layoutDetail = json.loads(cfg)

# copy the DISK temporary structure over the top of the new diskId name
layoutDetail["layout"][diskId] = layoutDetail["layout"]["DISK"]

# Now delete the DISK temporary structure
del layoutDetail["layout"]["DISK"]

####
#
#  Cleanup the structure details
#
####
# set the names and sizes on the partitions:
# Note: the sizes are NOT based on 1024, but 1000.
# subtract the size of the fat32 partition and a constant...
mySize = ( diskSize - 2000000000 ) / 1000000000
num = 1
for p in layoutDetail["layout"][diskId]["partitions"]:
	p["name"] = diskId + str(num)
	num += 1;
	if p["size"] == "MAX":
		p["size"] = str(int(mySize)) + "G"
		savedP = p

# The Members of the lvm
layoutDetail["layout"]["vg"]["members"] = [ savedP["name"] ]

# last but not least - fix the one mount detail
layoutDetail["mounts"]["/boot/efi"]["device"] = diskId + "1"

####
#
#  Output
#
####
hardware["storage-extra"] = layoutDetail

print('Saving custom storage layout to ' + os.environ['MAAS_RESOURCES_FILE'])
print(json.dumps(hardware))

with open(os.environ['MAAS_RESOURCES_FILE'], 'w') as fd:
    json.dump(hardware, fd)
```