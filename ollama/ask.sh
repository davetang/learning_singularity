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

SCRIPT_DIR=$(dirname $(realpath $0))
FOUND=0

trap '>&2 echo "Script terminated"; singularity instance stop ${INSTANCE_NAME} &> /dev/null; exit 1' INT TERM

if singularity instance list | grep -q ${INSTANCE_NAME}; then
   FOUND=1
fi

if [[ ${FOUND} == 1 ]]; then
   >&2 echo Found running instance: ${INSTANCE_NAME}
else
   >&2 echo Could not find ${INSTANCE_NAME}
   >&2 echo Starting ${INSTANCE_NAME}
   if ! singularity instance start --net --network none ${SCRIPT_DIR}/ollama.sif ${INSTANCE_NAME} > /dev/null; then
      >&2 echo "Error: failed to start instance"
      exit 1
   fi
   sleep 5
fi

>&2 echo "Running query..."
if ! singularity exec --net --network none instance://${INSTANCE_NAME} ollama run ${MODEL} "${PROMPT}"; then
    >&2 echo "Error: Failed to run Ollama model."
    exit 1
fi

if [[ ${FOUND} -eq 0 ]]; then
   >&2 echo "Stopping instance: ${INSTANCE_NAME}"
   singularity instance stop ${INSTANCE_NAME}
fi

>&2 echo Done
