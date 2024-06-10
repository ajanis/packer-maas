#!/bin/bash -e
#################################################
#
# maas-import-command.sh
#
# Generate 'maas boot-resources create' command
# with correct 'sha256sum' and 'byte size'
# for the newly created image.
#
# shellcheck disable=SC2312
#
#################################################

for image in harmonic.tar.gz harmonic-live.tar.gz; do
if [[ -e ${image} ]]; then
  cat <<EOF
  MAAS IMPORT:
  Copy the image to the MAAS server then
  Import the image to MAAS with the following command:

  maas admin boot-resources create name='custom/harmonic' title='Harmonic cOS' architecture='amd64/generic' filetype='tgz' sha256='$(sha256sum "${image}" | cut -d ' ' -f1)' size='$(stat -c'%s' "${image}")' content@='${image}'
EOF
fi
done
