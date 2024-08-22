#!/bin/bash
  
for host in maas maaspacker; do
echo -e "\nUploading to ${host}:"
rsync -azvp --delete --exclude 'liveiso' . "${host}":/opt/userdata/scripts/
done