#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 10 ]]; then
   >&2 echo Please provide a question with ten or more words
   >&2 echo Length of prompt: $#
   >&2 echo Prompt: $@
   exit 1
fi

PROMPT=$@

INSTANCE_NAME=ollama_instance

# find models at https://ollama.com/library
MODEL=deepseek-r1:32b

FOUND=0
if singularity instance list | grep -q ${INSTANCE_NAME}; then
   FOUND=1
fi

if [[ ${FOUND} == 1 ]]; then
   >&2 echo Found running instance: ${INSTANCE_NAME}
else
   >&2 echo Could not find ${INSTANCE_NAME}
   >&2 echo Starting ${INSTANCE_NAME}
   singularity instance start ollama.sif ${INSTANCE_NAME} > /dev/null
   sleep 5
fi

>&2 echo Running query
singularity exec instance://${INSTANCE_NAME} ollama run ${MODEL} "${PROMPT}"

>&2 echo Stopping ${INSTANCE_NAME}
singularity instance stop ${INSTANCE_NAME}
>&2 echo Done
