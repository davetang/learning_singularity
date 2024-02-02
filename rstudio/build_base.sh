#!/usr/bin/env bash

# Singularity uses /tmp, which is small on some of my servers
# Create and use a temp directory in ${HOME} instead
if [[ ! -d ${HOME}/tmp ]]; then
   mkdir ${HOME}/tmp
fi
export TMPDIR=$HOME/tmp

singularity build --fakeroot base.sif base.def
