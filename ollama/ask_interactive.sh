#!/usr/bin/env bash

set -euo pipefail

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
   singularity instance start --net --network none ollama.sif ${INSTANCE_NAME}
   sleep 5
fi

singularity exec --net --network none instance://${INSTANCE_NAME} ollama run ${MODEL}
