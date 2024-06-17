#!/bin/bash

for host in maas maaspacker; do
for i in harmonic-installer.sh ephemeral-deploy-command.sh user-data-bootcmd.yml user-data-curtin.yml user-data-late-commands.yml
do              
scp "${i}" "${host}":/opt/userdata/scripts/
done
done