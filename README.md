# FLOG_BFLOAT16
SystemVerilog implementation of the natural logarithm for a Floating Point Unit (FPU) employing the 16-bit brain-inspired floating-point format (bFloat).
In a 16-bit FPU we are implementing a module which computes the natural logarithm, the algorithm is based on the scientific paper
"Florent de Dinechin, Jérémie Detrey. Parameterized floating-point logarithm and exponential func- tions for FPGAs. 
Microprocessors and Microsystems: Embedded Hardware Design (MICPRO), Else- vier, 2006, 31 (8), pp.537-545. 10.1016/j.micpro.2006.02.008 . ensl-00542213"
We have implemented a FPU_log module and simulated it on Vivado, then compared its results with a MATLAB script and at the
end we instantiated it in the top module of the FPU.
Simulating the whole project we noted that our module takes 7 clock cycles between 2 consecutive operations, and the only error we are committing
is because of approximations errors between our module and the DPI, which causes an error of 1LSB in the mantissa.

# Licensing

BFloat16FPU is released under the *Solderpad Hardware Licence, Version 2.0*,
which is a permissive license based on Apache 2.0. Please refer to the
[license file](LICENSE.md) for further information.
