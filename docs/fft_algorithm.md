# Fast Fourier Transform (FFT) Algorithm Implementation

## Introduction

The Fast Fourier Transform (FFT) is an efficient algorithm for computing the Discrete Fourier Transform (DFT) of a sequence. This document explains the FFT algorithm implemented in this accelerator, focusing on the Radix-2 Decimation-in-Time (DIT) approach.

## The Discrete Fourier Transform

The Discrete Fourier Transform (DFT) converts a finite sequence of equally-spaced samples of a function into an equivalent-length sequence of equally-spaced samples of the discrete-time Fourier transform, which is a complex-valued function of frequency.

For a sequence of N complex numbers x₀, x₁, ..., x_{N-1}, the DFT is defined as:

X_k = ∑_{n=0}^{N-1} x_n · e^{-j2πkn/N} for k = 0, 1, ..., N-1

Where:
- X_k is the k-th DFT output
- x_n is the n-th input sample
- N is the size of the transform
- e^{-j2πkn/N} is the twiddle factor, often denoted as W_N^{kn}

## The Fast Fourier Transform

The FFT reduces the computational complexity of calculating the DFT from O(N²) to O(N log N) by exploiting the symmetry and periodicity properties of the twiddle factors.

### Radix-2 Decimation-in-Time (DIT) Algorithm

The Radix-2 DIT FFT recursively divides the N-point DFT into two (N/2)-point DFTs, one for the even-indexed samples and one for the odd-indexed samples:

X_k = ∑_{n=0}^{N/2-1} x_{2n} · W_N^{2nk} + ∑_{n=0}^{N/2-1} x_{2n+1} · W_N^{(2n+1)k}

Using the property that W_N^{2nk} = W_{N/2}^{nk}, we get:

X_k = E_k + W_N^k · O_k

Where:
- E_k is the k-th DFT output of the even-indexed samples
- O_k is the k-th DFT output of the odd-indexed samples

Also, due to the periodicity of the twiddle factors, we have:

X_{k+N/2} = E_k - W_N^k · O_k

This leads to the famous "butterfly" computation structure.

## Hardware Implementation

### Butterfly Unit

The butterfly operation is the core computation in the FFT algorithm. For each butterfly:

1. Two input values (A and B) are combined with a twiddle factor (W)
2. The outputs are calculated as:
   - A' = A + B·W
   - B' = A - B·W

The butterfly unit in hardware processes complex numbers using fixed-point arithmetic. Multiplication of complex numbers follows:

(a + bi) × (c + di) = (ac - bd) + (ad + bc)i

### Twiddle Factors

Twiddle factors (W_N^k) are precomputed and stored in ROM:

W_N^k = cos(2πk/N) - j·sin(2πk/N)

For a 64-point FFT, we need to store N/2 = 32 twiddle factors due to symmetry.

### Memory Access Patterns

The FFT algorithm requires specific memory access patterns:

1. In the non-pipelined design, data is accessed in a strided pattern that changes with each stage
2. In the pipelined design, delay elements (FIFOs) ensure proper data alignment

### Bit-Reversal Permutation

The Radix-2 DIT FFT produces outputs in bit-reversed order. To obtain outputs in natural order, a bit-reversal permutation is applied:

For an address i = (b_{n-1}, b_{n-2}, ..., b_1, b_0) in binary, the bit-reversed address is (b_0, b_1, ..., b_{n-2}, b_{n-1}).

## Implementation Details

### Fixed-Point Number Representation

Our implementation uses a Q1.{DATA_WIDTH-1} fixed-point format:
- 1 sign bit
- DATA_WIDTH-1 fractional bits

For example, with DATA_WIDTH=16:
- The value 1.0 is represented as 0x7FFF
- The value -1.0 is represented as 0x8000
- The value 0.5 is represented as 0x4000

### Computational Flow

The FFT computation proceeds through log₂(N) stages. For a 64-point FFT, this means 6 stages.

#### Non-pipelined Architecture
1. Load N input samples into memory
2. Process each stage sequentially:
   - For each butterfly pair, read values, compute, and write back
   - Update memory access patterns between stages
3. Apply bit-reversal permutation
4. Output results

#### Pipelined Architecture
1. Feed input samples sequentially
2. Data flows through log₂(N) pipeline stages
3. Each stage performs butterfly operations on appropriate sample pairs
4. Results emerge in natural order (bit-reversal incorporated into the pipeline structure)

### Optimizations

1. **Memory Management**: Using dual-port memory to allow simultaneous reads and writes
2. **Pipelining**: Breaking down the computation into stages for higher throughput
3. **Saturation Arithmetic**: Preventing overflow/underflow in fixed-point calculations
4. **Twiddle Factor Symmetry**: Using symmetry properties to reduce ROM size

## Error Analysis

Fixed-point arithmetic introduces quantization errors. The primary sources of error are:

1. Input quantization
2. Twiddle factor quantization
3. Computational rounding/truncation

With 16-bit fixed-point representation, the theoretical signal-to-noise ratio (SNR) is approximately 96 dB, which is sufficient for many applications.

## References

1. Cooley, J. W., & Tukey, J. W. (1965). "An algorithm for the machine calculation of complex Fourier series." *Mathematics of Computation*, 19(90), 297-301.
2. Oppenheim, A. V., & Schafer, R. W. (1975). "Digital Signal Processing." Prentice-Hall.
3. Proakis, J. G., & Manolakis, D. G. (2006). "Digital Signal Processing: Principles, Algorithms, and Applications." Prentice-Hall.