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

Stop instance when you're done (and confirm that it has been stopped).

```console
singularity instance stop ollama_serve
singularity instance list
```

# Ollama

[Where are models stored?](https://github.com/ollama/ollama/blob/main/docs/faq.md#where-are-models-stored)

On Linux `/usr/share/ollama/.ollama/models`; if a different directory needs to be used, set the environment variable `OLLAMA_MODELS` to the chosen directory.

> Note: on Linux using the standard installer, the ollama user needs read and write access to the specified directory. To assign the directory to the ollama user run sudo chown -R ollama:ollama <directory>.

[How can I specify the context window size?](https://github.com/ollama/ollama/blob/main/docs/faq.md#how-can-i-specify-the-context-window-size)

By default, Ollama uses a context window size of 2048 tokens. To change this when using `ollama run`, use `/set parameter num_ctx 4096`

[Does Ollama send my prompts and answers back to ollama.com?](https://github.com/ollama/ollama/blob/main/docs/faq.md#does-ollama-send-my-prompts-and-answers-back-to-ollamacom)

> No. Ollama runs locally, and conversation data does not leave your machine.
