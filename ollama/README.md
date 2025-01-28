# README

Build.

```console
./build.sh
```

Run `ollama`.

```console
singularity exec ollama.sif ollama --version
```
```
ollama version is 0.5.7
```

Start in shell mode.

```console
singularity shell ollama.sif
```

Run the following inside Singularity; change port in case of conflict.

```
export OLLAMA_HOST=127.0.0.1:11111
ollama serve &
ollama run llama3.2 "Tell me about bioinformatics"
```

Run in one command.

```console
singularity exec ollama.sif /bin/bash -c 'export OLLAMA_HOST=127.0.0.1:11112; ollama serve & ollama run llama3.2 "Tell me about bioinformatics"' > output
```
