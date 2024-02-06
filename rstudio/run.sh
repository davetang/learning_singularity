#!/usr/bin/env bash

IMG=./rstudio_server_verse_4.3.2.sif

if [[ ! -e ${IMG} ]]; then
   >&2 echo ${IMG} not found
   exit 1
fi

singularity run --bind ${HOME}:/home/rstudio ${IMG}
