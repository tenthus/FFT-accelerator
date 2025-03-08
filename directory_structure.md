# FFT Accelerator Project Directory Structure

The following is the recommended directory structure for organizing the FFT accelerator files:

```
fft-accelerator/
├── src/                 # Source Verilog files
│   ├── fft_top.v
│   ├── fft_controller.v
│   ├── fft_memory.v
│   ├── fft_butterfly.v
│   ├── fft_twiddle_rom.v
│   ├── fft_top_pipelined.v
│   ├── fft_pipeline.v
│   ├── fft_stage.v
│   ├── fifo.v
│   └── top_wrapper.v
│
├── testbench/           # Testbench files
│   ├── tb_fft_top.v
│   ├── tb_butterfly_unit.v
│   ├── tb_twiddle_factor_rom.v
│   └── tb_memory_controller.v
│
├── constraints/         # FPGA constraint files
│   ├── clock_constraints.sdc
│   └── pin_constraints.pcf
│
├── scripts/             # Automation scripts
│   ├── run_simulation.sh
│   ├── run_synthesis.sh
│   └── run_implementation.sh
│
├── docs/                # Documentation
│   ├── design_specs.md
│   ├── fft_algorithm.md
│   └── setup_guide.md
│
├── build/               # Build outputs (generated)
│   └── .gitkeep
│
├── sim_results/         # Simulation results (generated)
│   └── .gitkeep
│
├── apio.ini             # Apio configuration
└── README.md            # Project documentation
```

## Creating the Directory Structure

You can create this directory structure using the following commands:

```bash
mkdir -p fft-accelerator/src
mkdir -p fft-accelerator/testbench
mkdir -p fft-accelerator/constraints
mkdir -p fft-accelerator/scripts
mkdir -p fft-accelerator/docs
mkdir -p fft-accelerator/build
mkdir -p fft-accelerator/sim_results
touch fft-accelerator/build/.gitkeep
touch fft-accelerator/sim_results/.gitkeep
```

## File Categorization Guide

### Source Files (src/)

Place all Verilog implementation files in this directory:

- **Core FFT Modules**:
  - `fft_top.v`: Top-level module for non-pipelined FFT
  - `fft_controller.v`: Control unit for the FFT
  - `fft_memory.v`: Memory for data storage
  - `fft_butterfly.v`: Butterfly computation unit
  - `fft_twiddle_rom.v`: ROM for twiddle factors

- **Pipelined Implementation**:
  - `fft_top_pipelined.v`: Top-level module for pipelined FFT
  - `fft_pipeline.v`: Pipelined FFT implementation
  - `fft_stage.v`: Single stage of pipelined FFT
  - `fifo.v`: FIFO buffer for delay elements

- **FPGA Integration**:
  - `top_wrapper.v`: Wrapper for FPGA implementation

### Testbench Files (testbench/)

Place all verification files in this directory:

- `tb_fft_top.v`: Testbench for the top-level module
- `tb_butterfly_unit.v`: Testbench for the butterfly unit
- `tb_twiddle_factor_rom.v`: Testbench for the twiddle factor ROM
- `tb_memory_controller.v`: Testbench for the memory controller

### Constraint Files (constraints/)

Place all FPGA constraint files in this directory:

- `clock_constraints.sdc`: Specifies clock frequency and timing constraints
- `pin_constraints.pcf`: Maps I/O signals to FPGA pins

### Scripts (scripts/)

Place all automation scripts in this directory:

- `run_simulation.sh`: Automates simulation using Icarus Verilog
- `run_synthesis.sh`: Automates synthesis using Apio
- `run_implementation.sh`: Automates FPGA implementation using Apio

### Documentation (docs/)

Place all documentation files in this directory:

- `design_specs.md`: Design specifications and requirements
- `fft_algorithm.md`: FFT algorithm explanation
- `setup_guide.md`: Development environment setup guide

### Generated Directories

These directories are for generated files and should be excluded from version control:

- `build/`: Build outputs and synthesis results
- `sim_results/`: Simulation results and waveforms