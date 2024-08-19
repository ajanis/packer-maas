#!/bin/bash
export storcliBin="/usr/local/bin/storcli64"

# Define the controller ID
echo "Controller ID: 0"|chroma -s fruity
CONTROLLER_ID=0

# Define the drives for RAID 1 (replace with actual drive IDs)
echo "Drive IDs: 0:12, 0:13"|chroma -s fruity
DRIVES="0:12,0:13"

read -p "Enter to continue.."|chroma -s fruity
# Install storcli if not already installed (assuming the package is available in the repo)
if ! command -v "${storcliBin}" &> /dev/null
then
	    echo "${storcliBin} could not be found.."
	    exit 1
fi

# Show all controllers
echo "Listing all controllers..."|chroma -s fruity
"${storcliBin}" show all J | yq -r -C |chroma -s fruity

read -p "Enter to continue.."|chroma -s fruity


# Show enclosures
echo "Listing all enclosures..."|chroma -s fruity
"${storcliBin}" "/c${CONTROLLER_ID}" /eall show all J | yq -r -C |chroma -s fruity
read -p "Enter to continue.."|chroma -s fruity

# Show all drives connected to the controller
echo "Listing all drives for controller ${CONTROLLER_ID}..."|chroma -s fruity
"${storcliBin}" "/c${CONTROLLER_ID}" /eall /sall show all J | yq -r -C |chroma -s fruity
read -p "Enter to continue.."|chroma -s fruity


# Show Existing RAID 1 array
echo "Display existing  RAID 1 array..."|chroma -s fruity
"${storcliBin}" "/c${CONTROLLER_ID}" /vall show all J | yq -r -C  |chroma -s fruity
read -p "Enter to continue.."|chroma -s fruity

# Delete Existing RAID 1 array
echo "Delete existing  RAID 1 array..."|chroma -s fruity
"${storcliBin}" "/c${CONTROLLER_ID}" /vall delete J | yq -r -C  |chroma -s fruity
read -p "Enter to continue.."|chroma -s fruity

# Create New RAID 1 array
echo "Creating New RAID 1 array on controller ${CONTROLLER_ID} with drives ${DRIVES}..." | chroma -s fruity
"${storcliBin}" "/c${CONTROLLER_ID}" add vd type=raid1 drives="252:1,252:2" | chroma -s fruity
read -p "Enter to continue.."|chroma -s fruity

# Show NEW RAID 1 array
echo "Display NEW RAID 1 array..."|chroma -s fruity
"${storcliBin}" "/c${CONTROLLER_ID}" /vall show all J | yq -r -C  |chroma -s fruity
read -p "Enter to continue.."|chroma -s fruity