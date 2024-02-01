#!/usr/bin/env bash

R_VERSION=$(cat ./Singularity.def | grep R_VERSION= | cut -f2 -d'=')

if [[ -z ${R_VERSION} ]]; then
   echo Could not get R version
   exit 1
fi

singularity build --fakeroot rstudio_server_${R_VERSION}.sif Singularity.def
