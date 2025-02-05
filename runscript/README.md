# README

The `%runscript` section will be executed when using `singularity run`.

```
%runscript
    fortune | cowsay
    exec fortune | cowsay
```
```console
singularity run cowsay.sif
```
```
 __________________________________
/ Someone is speaking well of you. \
|                                  |
\ How unusual!                     /
 ----------------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
 _________________________________________
< Do something unusual today. Pay a bill. >
 -----------------------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```
