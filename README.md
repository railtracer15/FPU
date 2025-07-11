# IEEE 754 Floating Point Adder-Subtractor

This project implements a 64-bit Floating Point Unit (FPU) Adder-Subtractor based on the IEEE 754 double-precision standard. The module performs floating-point addition and subtraction with full compliance to the IEEE 754 specification.

## Features

- Supports 64-bit IEEE 754 double-precision floating point numbers  
- Performs addition and subtraction using a 1-bit operation selector  
- Handles special cases including:  
  - Zero  
  - Infinity  
  - NaN (Not a Number)  
  - Subnormal numbers  
  - Overflow and underflow
- Robust testbench that covers most of the cases.

## Interface

### Inputs
- `a [63:0]`: First operand (IEEE 754 double-precision format)  
- `b [63:0]`: Second operand (IEEE 754 double-precision format)  
- `op`: Operation selector  
  - `0`: Perform `a + b`  
  - `1`: Perform `a - b`  

### Output
- `result [63:0]`: The 64-bit IEEE 754 result of the operation  

## Usage

It is compatible with standard simulation tools for verification and validation.

## Future Work
- Floating Point Multiplier: Add support for IEEE 754-compliant multiplication.
- Floating Point Divider: Implement division functionality adhering to IEEE 754 standards.
- Pipelined Architecture: Introduce pipelining to improve throughput and operating frequency.


