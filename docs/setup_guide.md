# FFT Accelerator Setup Guide

This guide provides instructions for setting up the development environment, running simulations, and implementing the FFT accelerator on an FPGA using the Apio toolchain.

## Development Environment Setup

### Prerequisites

- Linux, macOS, or Windows with WSL recommended
- Python 3.6 or newer
- Git
- USB drivers for your FPGA board

### Installing Apio

Apio is an open-source ecosystem for FPGA development, mainly targeting the Lattice iCE40 family.

1. Install Python and pip if not already installed:
   ```bash
   # For Ubuntu/Debian
   sudo apt update
   sudo apt install python3 python3-pip
   
   # For macOS using Homebrew
   brew install python3
   ```

2. Install Apio and its dependencies:
   ```bash
   pip install apio
   apio install --all
   ```

3. Install the FTDI drivers for your FPGA board:
   ```bash
   apio drivers --ftdi-enable
   ```

4. Verify the installation:
   ```bash
   apio system --lsftdi
   ```
   This should detect your FPGA board if connected.

### Installing Icarus Verilog for Simulation

1. Install Icarus Verilog:
   ```bash
   # For Ubuntu/Debian
   sudo apt install iverilog
   
   # For macOS using Homebrew
   brew install icarus-verilog
   ```

2. Optional: Install GTKWave for viewing simulation waveforms:
   ```bash
   # For Ubuntu/Debian
   sudo apt install gtkwave
   
   # For macOS using Homebrew
   brew install gtkwave
   ```

## Project Structure

The FFT accelerator project uses the following directory structure:

```
fft-accelerator/
├── src/                # Source Verilog files
├── testbench/          # Testbench files
├── constraints/        # FPGA constraint files
├── scripts/            # Automation scripts
├── docs/               # Documentation
├── build/              # Build outputs (generated)
└── sim_results/        # Simulation results (generated)
```

## Getting Started

### Cloning the Repository

```bash
git clone https://github.com/yourusername/fft-accelerator.git
cd fft-accelerator
```

### Directory Setup

Create the necessary directories if they don't exist:

```bash
mkdir -p src testbench constraints scripts docs build sim_results
```

### Configuring for Your FPGA Board

Edit the `apio.ini` file to specify your FPGA board:

```ini
[env]
board = icestick  # Change to your board: icestick, icezum, etc.
```

## Running Simulations

The project provides scripts to automate simulation tasks.

### Running All Testbenches

```bash
cd scripts
chmod +x run_simulation.sh
./run_simulation.sh
```

This will run all testbenches and save results in the `sim_results` directory.

### Running a Specific Testbench

```bash
cd testbench
iverilog -o tb_fft_top.vvp ../src/*.v tb_fft_top.v
vvp tb_fft_top.vvp
```

### Viewing Waveforms

```bash
gtkwave sim_results/vcd/tb_fft_top.vcd
```

## Synthesizing and Implementing on FPGA

### Running Synthesis

```bash
cd scripts
chmod +x run_synthesis.sh
./run_synthesis.sh
```

This will synthesize the design and generate a bitstream in the `build` directory.

### Programming the FPGA

```bash
cd scripts
chmod +x run_implementation.sh
./run_implementation.sh
```

This will upload the bitstream to your connected FPGA board.

## Manual FPGA Implementation with Apio

If you prefer to run the Apio commands manually:

1. Verify the design:
   ```bash
   apio verify
   ```

2. Synthesize the design:
   ```bash
   apio build
   ```

3. Upload to FPGA:
   ```bash
   apio upload
   ```

4. Clean build files:
   ```bash
   apio clean
   ```

## Testing the FFT Accelerator on Hardware

After uploading the bitstream to your FPGA, you can test the FFT accelerator:

1. The LEDs on the board indicate the status:
   - LED0: Busy (computation in progress)
   - LED1: Done (computation completed)
   - LED2: Data output valid
   - LED3: Loading state
   - LED4: Output state

2. Use the onboard buttons or GPIO pins to control the accelerator:
   - Reset (active low): Initialize the system
   - Start: Begin FFT computation
   - Input data can be provided through GPIO pins or an external interface

## Troubleshooting

### Common Issues

1. **FPGA not detected**
   - Check USB connection
   - Ensure FTDI drivers are installed
   - Try running `apio system --lsftdi`

2. **Synthesis fails**
   - Check for syntax errors in Verilog files
   - Ensure timing constraints are appropriate
   - Verify that the design fits within FPGA resources

3. **Testbench errors**
   - Check that all dependencies are included
   - Verify input test vectors
   - Check output file paths

### Getting Help

- Check the Apio documentation: [Apio GitHub](https://github.com/FPGAwars/apio)
- For board-specific issues, refer to your FPGA board's documentation
- For FFT algorithm questions, refer to the `fft_algorithm.md` document

## Advanced Configuration

### Modifying the FFT Size

To change the FFT size, modify the `FFT_POINTS` parameter in the top-level module instantiation:

```verilog
fft_top #(
    .DATA_WIDTH(16),
    .FFT_POINTS(128),     // Change from 64 to 128
    .ADDR_WIDTH(7)        // log2(128) = 7
) fft_inst (
    // ports
);
```

### Modifying the Data Width

To change the data width, modify the `DATA_WIDTH` parameter:

```verilog
fft_top #(
    .DATA_WIDTH(24),      // Change from 16 to 24
    .FFT_POINTS(64),
    .ADDR_WIDTH(6)
) fft_inst (
    // ports
);
```

Remember to also update the twiddle factor ROM with appropriate precision for the new data width.

## References

1. [Apio Documentation](https://github.com/FPGAwars/apio)
2. [Icarus Verilog Documentation](https://iverilog.fandom.com/wiki/Main_Page)
3. [Lattice iCE40 Documentation](https://www.latticesemi.com/iCE40)