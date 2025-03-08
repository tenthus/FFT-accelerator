# Fast Fourier Transform (FFT) Accelerator Design Specifications

## Overview

This document provides the design specifications for a hardware FFT accelerator implemented in Verilog. The accelerator is designed to be synthesizable on FPGAs using the Apio toolchain and offers both pipelined and non-pipelined architectural options.

## Functional Requirements

The FFT accelerator shall:

1. Implement a configurable-point Radix-2 Decimation-in-Time (DIT) FFT algorithm
2. Support FFT sizes that are powers of 2 (e.g., 16, 32, 64, 128, 256)
3. Process complex input data (real and imaginary components)
4. Provide natural-order output through bit-reversal permutation
5. Be configurable in terms of data width
6. Provide status signals (busy, done) for external control logic
7. Be synthesizable with the Apio toolchain for FPGA deployment

## Technical Specifications

### Data Format and Precision

- Data width: Configurable, default is 16 bits
- Data representation: Fixed-point Q1.(DATA_WIDTH-1) format
- Complex number representation: Split into separate real and imaginary components

### Performance Requirements

#### Non-pipelined Architecture
- Throughput: One N-point FFT every O(N log N) clock cycles
- Latency: O(N log N) clock cycles
- Resource utilization: Lower than pipelined architecture

#### Pipelined Architecture
- Throughput: One N-point FFT output every N clock cycles after initial latency
- Latency: O(N) clock cycles for first output
- Resource utilization: Higher than non-pipelined architecture

### Interface Specifications

#### Common Signals
- `clk`: System clock input
- `rst_n`: Active-low asynchronous reset
- `start`: Start FFT computation
- `data_valid`: Input data valid flag
- `data_in_real`: Real part of input data
- `data_in_imag`: Imaginary part of input data
- `busy`: FFT computation in progress
- `done`: FFT computation complete

#### Non-pipelined FFT Interface
- `addr_in`: Input data address
- `rd_en`: Read enable for output data
- `addr_out`: Output data address
- `data_out_real`: Real part of output data
- `data_out_imag`: Imaginary part of output data

#### Pipelined FFT Interface
- `data_out_valid`: Output data valid flag
- `data_out_real`: Real part of output data
- `data_out_imag`: Imaginary part of output data

### Resource Utilization Targets

- Logic elements: < 5,000 LUTs for 64-point FFT (16-bit)
- Block RAM: < 10 BRAMs for 64-point FFT (16-bit)
- DSP blocks: < 8 DSPs for 64-point FFT (16-bit)

These targets are intended for moderate-size FPGAs like the Lattice iCE40 HX8K.

## Architectural Design

### Non-pipelined Architecture

The non-pipelined architecture consists of:
1. Memory controller for data management
2. Single butterfly unit for FFT computation
3. Twiddle factor ROM for complex coefficient storage
4. Dual-port memory for data storage
5. Control unit for orchestrating the FFT computation

This architecture optimizes for resource utilization at the expense of throughput.

### Pipelined Architecture

The pipelined architecture consists of:
1. Input buffer for data loading
2. log₂(N) FFT stages, each with:
   - Delay elements (FIFOs)
   - Butterfly computation units
   - Twiddle factor ROMs
3. Output buffer for result storage

This architecture optimizes for throughput at the expense of resource utilization.

## Configuration Parameters

The FFT accelerator is configurable through the following parameters:

- `DATA_WIDTH`: Width of data samples (default: 16)
- `FFT_POINTS`: Number of FFT points (default: 64)
- `ADDR_WIDTH`: Address width, equal to log₂(FFT_POINTS)

## Implementation Constraints

- Target clock frequency: 12-100 MHz (depending on FPGA capability)
- Minimal use of advanced FPGA features to ensure portability across devices
- Compliance with Apio toolchain requirements

## Testing and Verification

The FFT accelerator shall be verified against:
1. Basic FFT functionality with known input patterns
2. Accuracy compared to software FFT implementations
3. Timing constraints for target FPGA devices
4. Resource utilization targets

Test cases shall include:
1. Impulse response
2. Sine wave input
3. Square wave input
4. Random data

## References

1. Cooley, J. W., & Tukey, J. W. (1965). "An algorithm for the machine calculation of complex Fourier series." *Mathematics of Computation*, 19(90), 297-301.
2. Smith, S. W. (1997). "The Scientist and Engineer's Guide to Digital Signal Processing." California Technical Publishing.
3. Meyer-Baese, U. (2007). "Digital Signal Processing with Field Programmable Gate Arrays." Springer.