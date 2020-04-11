# FLOG_BFLOAT16

Implementation of the base 2 logarithm in a BFloat16 floating-point format, built for a [Floating-point unit with support for BFloat16 floating-point format](https://gitlab.com/davide.zoni/bfloat_fpu_systemverilog), written in SystemVerilog.


Maintainers (in alphabetical order):

  - Andrea Buffoli andrea.buffoli@mail.polimi.it
  
  - Matteo Giacomello matteo.giacomello@mail.polimi.it
  
  - Artem Glukhov artem.glukhov@mail.polimi.it
  
  - Giacomo Ticchi giacomo.ticchi@mail.polimi.it
  
  
## Features

### Format
Being the input a floating-point value in form (S,E,M),
(assuming the sign always positive for our purposes)

being 

`X=m*2^e`

and

`Y=log_2(X) = e + log_2(m)`


The result of `log_2(m)` is based on the following algorithm: [P. W. Philo, "An algorithm to evaluate the logarithm of a number to base 2, in binary form," in Radio and Electronic Engineer, vol. 38, no. 1, pp. 49-50, July 1969.](https://ieeexplore.ieee.org/document/5267549)

Then `Y` is transformed back to BFloat16 format (through the i2f module) and the output will be again in (S,E,M) format.

### Testbench

The first testbench, also written in SystemVerilog, performes a `log_2` of 100 randomly selected numbers with both the RTL logic and a DPI (Direct Programming Interface) written in C, and outputs the results in a csv plain text file.
Another testbench was written in order to test all the possible inputs in the BFloat16 format (in a brute force approach). In this way we get all the necessary data to evaluate the average error in our computation and other useful parameters, parsing the data through MATLAB.

### Performance

For what concerns temporal performances the module performs the log2 of all the possible inputs in 39ms (clock period = 40ns). The worst case computation takes 37 clock cycles, while the best case (special case values) takes 2 clock cycles. In average an input is processed in almost 1.2us, corresponding to 30 clock cycles.

While for what concerns precision, the average error is 0.003491 with a maximum error of |0.250|. MATLAB plots will give further informations about this.

### Rounding
The rounding method used up to now is the "Nearest Even" method (which is the default rounding of the IEEE-754 standard).

## Licencing

FLOG_BFLOAT16 is released under Apache Licence, Version 2.0, which is a permissive license whose main conditions require preservation of copyright and license notices. Contributors provide an express grant of patent rights. Licensed works, modifications, and larger works may be distributed under different terms and without source code. Please refer to the
[license file](https://github.com/artemglukhov/FLOG_BFLOAT16/blob/master/LICENSE) for further information.
