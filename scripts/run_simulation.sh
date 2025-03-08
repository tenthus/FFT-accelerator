#!/bin/bash
# Run simulation for FFT Accelerator using Icarus Verilog

# Create output directories
mkdir -p sim_results
mkdir -p sim_results/vcd
mkdir -p sim_results/log

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting FFT Accelerator Simulation${NC}"

# List of modules to simulate
declare -a MODULES=("tb_fft_top" "tb_butterfly_unit" "tb_twiddle_factor_rom" "tb_memory_controller")

# Source file dependencies
SOURCE_FILES="../src/fft_top.v ../src/fft_controller.v ../src/fft_memory.v ../src/fft_butterfly.v ../src/fft_twiddle_rom.v ../src/fft_pipeline.v ../src/fft_stage.v ../src/fifo.v ../src/fft_top_pipelined.v"

# Run simulations for each module
for MODULE in "${MODULES[@]}"
do
    echo -e "${YELLOW}Compiling and running ${MODULE}...${NC}"
    
    # Compile with Icarus Verilog
    iverilog -o sim_results/${MODULE}.vvp ${SOURCE_FILES} ../testbench/${MODULE}.v
    
    # Check compilation status
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Compilation successful!${NC}"
        
        # Run simulation
        vvp sim_results/${MODULE}.vvp > sim_results/log/${MODULE}.log
        
        # Check simulation status
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Simulation of ${MODULE} completed successfully!${NC}"
            
            # Check if VCD file was generated
            if [ -f "${MODULE}.vcd" ]; then
                mv ${MODULE}.vcd sim_results/vcd/
                echo -e "${GREEN}VCD file moved to sim_results/vcd/${MODULE}.vcd${NC}"
            fi
            
            # Check for any output files and move them
            if ls *.txt 1> /dev/null 2>&1; then
                mv *.txt sim_results/
                echo -e "${GREEN}Text output files moved to sim_results/${NC}"
            fi
        else
            echo -e "${RED}Simulation of ${MODULE} failed!${NC}"
        fi
    else
        echo -e "${RED}Compilation of ${MODULE} failed!${NC}"
    fi
    
    echo -e "${YELLOW}--------------------------------------------${NC}"
done

echo -e "${GREEN}All simulations completed!${NC}"
echo -e "${YELLOW}Results can be found in the sim_results directory${NC}"
echo -e "${YELLOW}To view waveforms, use a VCD viewer like GTKWave:${NC}"
echo -e "${YELLOW}gtkwave sim_results/vcd/tb_fft_top.vcd${NC}"

exit 0