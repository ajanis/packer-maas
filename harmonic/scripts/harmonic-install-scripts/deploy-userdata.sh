#!/bin/bash

for host in maas maaspacker; do
for i in harmonic-installer.sh ephemeral-deploy-command.sh harmonic-user-data-download.cloud-init harmonic-user-data-writefile.cloud-init maas-import-command.sh curtin-user-data.yml 
do              
scp "${i}" "${host}":/opt/userdata/scripts/
done
done