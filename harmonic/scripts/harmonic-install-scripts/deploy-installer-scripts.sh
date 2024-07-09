#!/bin/bash -x

if [[ -f $1 ]]; then
fileList=$1
else
fileList=(harmonic-installer.sh ephemeral-deploy-command.sh user-data-bootcmd.yml user-data-curtin.yml user-data-late-commands.yml)
fi

for host in maas maaspacker; do
for file in "${fileList[@]}"; do           
scp "${file}" "${host}":/opt/userdata/scripts/
done
done
