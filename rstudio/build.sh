#!/usr/bin/env bash

R_VERSION=$(cat ./Singularity.def | grep R_VERSION= | cut -f2 -d'=')
if [[ -z ${R_VERSION} ]]; then
   echo Could not get R version
   exit 1
fi

RSTUDIO_VERSION=$(basename $(cat ./Singularity.def | grep RSTUDIO_SERVER_URL= | cut -f2 -d'=') .deb)
if [[ -z ${RSTUDIO_VERSION} ]]; then
   echo Could not get RStudio Server version
   exit 1
fi

singularity build --fakeroot ${RSTUDIO_VERSION}-R-${R_VERSION}.sif Singularity.def
