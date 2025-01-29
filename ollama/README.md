# README

Build image.

```console
./build.sh
```

Start as [service](https://docs.sylabs.io/guides/4.2/user-guide/running_services.html).

```console
singularity instance start ollama.sif ollama_serve
```

List instances in case you forgot the name.

```console
singularity instance list
```

Interact with instance.

```console
singularity exec instance://ollama_serve ollama --version
```
```
ollama version is 0.5.7
```

Run from instance.

```console
singularity exec instance://ollama_serve ollama run llama3.2 "Tell me about bioinformatics"
```
```
Bioinformatics is an interdisciplinary field that combines computer science, mathematics, and biology to analyze and interpret
biological data. It involves the use of computational tools and methods to understand the structure, function, and evolution of
living organisms.
...
```
