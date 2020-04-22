# BFloat16FPU

Floating-point unit with support for BFloat16 floating-point format,
written in SystemVerilog.

Maintainers (in alphabetical order):
- Andrea Galimberti <andrea.galimberti@polimi.it>
- Davide Zoni <davide.zoni@polimi.it>

## Features

### Format
BFloat16FPU supports the BFloat16 floating-point format.
BFloat16 is a truncated 16-bit version of the 32-bit IEEE 754 single-precision
floating-point format (Float32), with the intent of accelerating machine
learning and near-sensor computing. It preserves the range of 32-bit
floating-point numbers by retaining 8 exponent bits, but supports only an
8-bit precision rather than the 24-bit significand of the Float32 format.

### Operations
BFloat16FPU supports the follwing operations:
- Addition/Subtraction
- Multiplication
- Division
- Comparisons
- Conversions between BFloat16 and signed integer (32-bit) formats

Some compliance issues with IEEE 754-2008 are currently known to exist.

### Rounding modes
BFloat16FPU supports the following IEEE 754-2008 rounding modes:
- roundTiesToEven
- roundTowardZero

## Licensing

BFloat16FPU is released under the *Solderpad Hardware Licence, Version 2.0*,
which is a permissive license based on Apache 2.0. Please refer to the
[license file](LICENSE.md) for further information.

## Acknowledgement
This work was partially supported by the European Commission under Grant No. 732631 – H2020 Research and Innovation Programme: OPRECOMP.
