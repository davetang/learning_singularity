# Build testing

Simple build.

```singularity
Bootstrap: docker
From: debian:bullseye-slim

%runscript
    exec /usr/local/bin/hello.sh

%post
printf '#!/usr/bin/env bash\necho Hi there\n' > /usr/local/bin/hello.sh &&
chmod 755 /usr/local/bin/hello.sh
```

The following needs to fail but the build continues. (Using
`remotes::install_cran` is the same but not shown here.)

```singularity
Bootstrap: docker
From: rocker/r-ver:4.3.2

%post
R -q -e 'install.packages("thisdoesnotexist!!!")'
```

Build.

```console
singularity build --fakeroot --force test.sif r.def
```
```
INFO:    Running post scriptlet
+ R -q -e install.packages("thisdoesnotexist!!!")
> install.packages("thisdoesnotexist!!!")
Installing package into ‘/usr/local/lib/R/site-library’
(as ‘lib’ is unspecified)
Warning message:
package ‘thisdoesnotexist!!!’ is not available for this version of R

A version of this package for your version of R might be available elsewhere,
see the ideas at
https://cran.r-project.org/doc/manuals/r-patched/R-admin.html#Installing-packages
>
>
INFO:    Creating SIF file...
INFO:    Build complete: test.sif
```

In the shell (`/bin/sh`) the exit code is 1.

```console
R -q -e 'install.packages("thisdoesnotexist!!!")'
echo $?
# 1
```

Use `tryCatch` and "convert" message into an error.

```singularity
Bootstrap: docker
From: rocker/r-ver:4.3.2

%post
R -q -e 'tryCatch(message = function(x) stop("Warning message detected"), install.packages("Thisdoesnotexist!@!!"))'
```

Build.

```console
singularity build --fakeroot --force test.sif r.def
```
```
INFO:    Running post scriptlet
+ R -q -e tryCatch(message = function(x) stop("Warning message detected"), install.packages("Thisdoesnotexist!@!!"))
> tryCatch(message = function(x) stop("Warning message detected"), install.packages("Thisdoesnotexist!@!!"))
Error in value[[3L]](cond) : Warning message detected
Calls: tryCatch -> tryCatchList -> tryCatchOne -> <Anonymous>
Execution halted
FATAL:   While performing build: while running engine: exit status 1
```
