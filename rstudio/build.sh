#!/usr/bin/env bash

# Singularity uses /tmp, which is small on some of my servers
# Create and use a temp directory in ${HOME} instead
if [[ ! -d ${HOME}/tmp ]]; then
   mkdir ${HOME}/tmp
fi
export TMPDIR=$HOME/tmp

R_VERSION=$(cat ./Singularity.def | grep "rocker/verse" | cut -f3 -d':')
if [[ -z ${R_VERSION} ]]; then
   echo Could not get R version
   exit 1
fi

singularity build --fakeroot rstudio_server_verse_${R_VERSION}.sif Singularity.def
