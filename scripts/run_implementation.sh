#!/bin/bash
# Run implementation (upload to FPGA) for FFT Accelerator using APIO

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting FFT Accelerator Implementation (Upload to FPGA)${NC}"

# Check if APIO is installed
if ! command -v apio &> /dev/null; then
    echo -e "${RED}APIO is not installed or not in PATH!${NC}"
    echo -e "${YELLOW}Please install APIO using: pip install apio${NC}"
    echo -e "${YELLOW}Then initialize APIO with: apio install${NC}"
    exit 1
fi

# Return to project root directory if in scripts folder
if [[ $(basename $(pwd)) == "scripts" ]]; then
    cd ..
fi

# Check if the bitstream exists
if [ ! -f "build/top_wrapper.bin" ]; then
    echo -e "${RED}Bitstream not found!${NC}"
    echo -e "${YELLOW}Please run ./scripts/run_synthesis.sh first${NC}"
    exit 1
fi

# Read the board from apio.ini
BOARD=$(grep "board" apio.ini | cut -d'=' -f2 | tr -d ' ')

echo -e "${YELLOW}Target board: ${BOARD}${NC}"
echo -e "${YELLOW}Uploading to FPGA...${NC}"

# Check FPGA connection
echo -e "${YELLOW}Checking FPGA connection...${NC}"
apio system --lsftdi
if [ $? -ne 0 ]; then
    echo -e "${RED}No FPGA found or connection error!${NC}"
    echo -e "${YELLOW}Please check if the FPGA is connected and detected by your system${NC}"
    exit 1
fi

# Upload bitstream to FPGA
echo -e "${YELLOW}Uploading bitstream to FPGA...${NC}"
apio upload
if [ $? -ne 0 ]; then
    echo -e "${RED}Upload failed!${NC}"
    echo -e "${YELLOW}Please check if the FPGA is properly connected and configured${NC}"
    exit 1
fi

echo -e "${GREEN}Implementation completed!${NC}"
echo -e "${GREEN}Bitstream successfully uploaded to FPGA!${NC}"

# Check if we can time the design
if command -v icetime &> /dev/null; then
    echo -e "${YELLOW}Estimated performance:${NC}"
    grep "Max frequency" build/top_wrapper.rpt 2>/dev/null || echo -e "${YELLOW}Performance information not available${NC}"
fi

echo -e "${YELLOW}FFT Accelerator is now running on the FPGA!${NC}"
echo -e "${YELLOW}LED indicators:${NC}"
echo -e "${YELLOW}- LED0: Busy status${NC}"
echo -e "${YELLOW}- LED1: Done status${NC}"
echo -e "${YELLOW}- LED2: Data output valid${NC}"
echo -e "${YELLOW}- LED3: Loading state${NC}"
echo -e "${YELLOW}- LED4: Output state${NC}"

exit 0