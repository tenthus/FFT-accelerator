# Clock constraints for FFT Accelerator
# SDC (Synopsys Design Constraints) format

# Primary clock definition
create_clock -name clk -period 83.333 [get_ports clk]
# 83.333ns = 12MHz (Default for icestick)

# For higher performance (e.g., 48MHz), use:
# create_clock -name clk -period 20.833 [get_ports clk]

# For very high performance (100MHz), use:
# create_clock -name clk -period 10.000 [get_ports clk]

# Specify clock uncertainty
set_clock_uncertainty 0.5 [get_clocks clk]

# Input delay constraints
set_input_delay -clock clk -max 10.0 [get_ports {data_in_*}]
set_input_delay -clock clk -max 10.0 [get_ports {addr_in}]
set_input_delay -clock clk -max 10.0 [get_ports {start}]
set_input_delay -clock clk -max 10.0 [get_ports {data_valid}]
set_input_delay -clock clk -max 10.0 [get_ports {rd_en}]
set_input_delay -clock clk -max 10.0 [get_ports {addr_out}]

# Output delay constraints
set_output_delay -clock clk -max 10.0 [get_ports {data_out_*}]
set_output_delay -clock clk -max 10.0 [get_ports {busy}]
set_output_delay -clock clk -max 10.0 [get_ports {done}]

# Reset timing requirements
set_false_path -from [get_ports rst_n]

# Multicycle paths
# The butterfly computation takes 2 clock cycles, so we can use multicycle path constraints
set_multicycle_path -from [get_pins {butterfly_inst/data_*_reg*/Q}] -to [get_pins {butterfly_inst/out_*_reg*/D}] -setup 2
set_multicycle_path -from [get_pins {butterfly_inst/data_*_reg*/Q}] -to [get_pins {butterfly_inst/out_*_reg*/D}] -hold 1

# Critical paths specifically for the FFT butterfly computation
set_max_delay 70.0 -from [get_pins {butterfly_inst/data_*_reg*/Q}] -to [get_pins {butterfly_inst/out_*_reg*/D}]

# Comment out or modify constraints as needed based on your specific FPGA hardware and requirements