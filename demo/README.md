# Build testing

Simple build with testing.

```singularity
Bootstrap: docker
From: debian:bullseye-slim

%runscript
    exec /usr/local/bin/hello.sh

%post
    printf '#!/usr/bin/env bash\necho Hi there\n' > /usr/local/bin/hello.sh \
    && chmod 755 /usr/local/bin/hello.sh

%test
    /usr/local/bin/hello.sh
```

## Test section

However **only the last command** of the `%test` section matters! Singularity
continues to build the following image.

```singularity
Bootstrap: docker
From: debian:bullseye-slim

%runscript
    exec /usr/local/bin/hello.sh

%post
    printf '#!/usr/bin/env bash\necho Hi there\n' > /usr/local/bin/hello.sh \
    && chmod 755 /usr/local/bin/hello.sh

%test
    laksdjf
    echo $?
    /usr/local/bin/hello.sh
```

Build.

```console
singularity build --fakeroot --force blah.sif test_demo.def
```
```
INFO:    Starting build...
INFO:    Running post scriptlet
+ printf #!/usr/bin/env bash\necho Hi there\n
+ chmod 755 /usr/local/bin/hello.sh
INFO:    Adding runscript
INFO:    Adding testscript
INFO:    Running testscript
/.singularity.d/test: 3: laksdjf: not found
127
Hi there
INFO:    Creating SIF file...
INFO:    Build complete: blah.sif
```

The test section is supposed to work like a script. Therefore, we can use Bash
and the use `set -e` to catch failing commands.

```singularity
Bootstrap: docker
From: debian:bullseye-slim

%runscript
    exec /usr/local/bin/hello.sh

%post
    printf '#!/usr/bin/env bash\necho Hi there\n' > /usr/local/bin/hello.sh \
    && chmod 755 /usr/local/bin/hello.sh

%test
    /bin/bash
    set -e
    laksdjf
    echo $?
    /usr/local/bin/hello.sh
```

The build will now fail, as expected.

```console
singularity build --fakeroot --force blah.sif test_bash.def
```
```
INFO:    Starting build...
INFO:    Running post scriptlet
+ printf #!/usr/bin/env bash\necho Hi there\n
+ chmod 755 /usr/local/bin/hello.sh
INFO:    Adding runscript
INFO:    Adding testscript
INFO:    Running testscript
/.singularity.d/test: 5: laksdjf: not found
FATAL:   While performing build: failed to execute %test script: exit status 127
```

## R install.packages()

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
