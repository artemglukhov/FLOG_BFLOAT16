# FLOG_BFLOAT16

Implementation of the base 2 logarithm in a BFloat16 floating-point format, built for a [Floating-point unit with support for BFloat16 floating-point format](https://gitlab.com/davide.zoni/bfloat_fpu_systemverilog), written in SystemVerilog.


Maintainers (in alphabetical order):

  - Andrea Buffoli andrea.buffoli@mail.polimi.it
  
  - Matteo Giacomello matteo.giacomello@mail.polimi.it
  
  - Artem Glukhov artem.glukhov@mail.polimi.it
  
  - Giacomo Ticchi giacomo.ticchi@mail.polimi.it
  
  
## Features

### Format
Beeing the input a floating-point value in form (S,E,M),
(assuming the sign always positive for our purposes)

beeing 

`X=m*2^e`

and

`Y=log_2(X) = e + log_2(m)`


The result of `log_2(m)` is based on the following algorithm: [P. W. Philo, "An algorithm to evaluate the logarithm of a number to base 2, in binary form," in Radio and Electronic Engineer, vol. 38, no. 1, pp. 49-50, July 1969.](https://ieeexplore.ieee.org/document/5267549)

Then `Y` is transformed back to BFloat16 format and the output will be in (S,E,M) format.

### Testbench

The testbench, also written in SystemVerilog, performes a `log_2` of 100 randomly selected numbers with both the RTL logic and a DPI (Direct Programming Interface) written in C, and outputs the results in a csv plain text file.

### Performance

> ***TODO***

### Rounding

> ***TODO***

## Licencing

FLOG_BFLOAT16 is released under Apache Licence, Version 2.0, which is a permissive license whose main conditions require preservation of copyright and license notices. Contributors provide an express grant of patent rights. Licensed works, modifications, and larger works may be distributed under different terms and without source code. Please refer to the
[license file](https://github.com/artemglukhov/FLOG_BFLOAT16/blob/master/LICENSE) for further information.
