# FLOG_BFLOAT16
## Maintainers (in alphabetical order):
- Andrea  Buffoli    <andrea.buffoli@polimi.it>
- Matteo  Giacomello <matteo.giacomello@polimi.it>
- Artem   Glukhov    <artem.glukhov@polimi.it>
- Giacomo Ticchi     <giacomo.ticchi@polimi.it>

## Brief overview

In this project we've added the natural logarithm operation in an already existing Floating Point Unit 16 bits running at 100Mhz.
>The algorithm of our code is based on the scientific paper by [Florent de Dinechin, Jérémie Detrey](https://hal-ens-lyon.archives-ouvertes.fr/ensl-00542213/file/DetreyDinechinJMM.pdf).

After the design of our IPcore we have compared its results with the one of a DPI code written in C and we have noticed some errors (due to rounding approximations) occurring in the LSB of the fractional part. Using Matlab we have quantified all these errors computing some usefull stastical error parameters. Finally simulating the whole FPU we noted that it takes 6 clock cycles between 2 consecutive logarithm operations with a WNS = 0.218ns (WNS refers to post-implementation).

## Folder structure

### bfloat_fpu_systemverilog
Final implementation of the module inside the LAMP FPU.

### Local
Standalone implementation of the flog module with its own testbench.

### REPORT
Report of the final project.

### OLD
A bunch of old and deprecated code.

## Licensing

BFloat16FPU is released under the *Solderpad Hardware Licence, Version 2.0*,
which is a permissive license based on Apache 2.0. Please refer to the
[license file](LICENSE.md) for further information.
