#!/bin/bash -e
#################################################
#
# maas-import-command.sh
#
# Generate 'maas boot-resources create' command
# with correct 'sha256sum' and 'byte size'
# for the newly created image.
#
#################################################
# shellcheck disable=SC2312
mapfile -t FILE_ARRAY < <( jq '.builds[].files[].name' manifest.json )
for FILE in "${FILE_ARRAY[@]}"; do
	if [[ -e "${FILE}" && "${FILE}" == "harmonic-installer.tar.gz" ]]; then
		  cat <<EOF
  MAAS IMPORT:
  Copy the image to the MAAS server then
  Import the image to MAAS with the following command:

  maas admin boot-resources create name='custom/harmonic' title='Harmonic cOS' architecture='amd64/generic' filetype='tgz' sha256='$(sha256sum harmonic-installer.tar.gz | cut -d ' ' -f1)' size='$(stat -c'%s' harmonic-installer.tar.gz)' content@='harmonic-installer.tar.gz'
EOF
	fi
done
