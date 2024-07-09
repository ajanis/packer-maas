#!/bin/bash

if [[ -f $1 ]]; then
fileList=$1
else
mapfile -d '' fileList < <(find . -type f ! -name '*.tgz') || true
fi

# for file in "${fileList[@]}"; do     
for host in maas maaspacker; do
echo -e "\nUploading to ${host}:"
rsync -azp --delete --recursive  ${fileList[@]}  "${host}":/opt/userdata/scripts/
rsync -azp --delete --exclude '*.tgz' . "${host}":/opt/userdata/scripts/
done
