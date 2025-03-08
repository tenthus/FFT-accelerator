/**
 * Fast Fourier Transform Accelerator - Top Module
 * 
 * This module serves as the top-level entity for the FFT accelerator.
 * It implements a configurable-point FFT with parameterized bit width.
 */
 module fft_top #(
    parameter DATA_WIDTH = 16,     // Width of data samples
    parameter FFT_POINTS = 64,     // Number of FFT points (must be power of 2)
    parameter ADDR_WIDTH = 6       // log2(FFT_POINTS)
)(
    input                       clk,          // System clock
    input                       rst_n,        // Active low reset
    input                       start,        // Start FFT computation
    input                       data_valid,   // Input data valid
    input  [DATA_WIDTH-1:0]     data_in_real, // Input data (real part)
    input  [DATA_WIDTH-1:0]     data_in_imag, // Input data (imaginary part)
    input  [ADDR_WIDTH-1:0]     addr_in,      // Input data address
    input                       rd_en,        // Read enable
    input  [ADDR_WIDTH-1:0]     addr_out,     // Output data address
    
    output                      busy,         // FFT computation in progress
    output                      done,         // FFT computation complete
    output [DATA_WIDTH-1:0]     data_out_real,// Output data (real part)
    output [DATA_WIDTH-1:0]     data_out_imag // Output data (imaginary part)
);

    // Internal signals
    wire                      memory_we;
    wire [ADDR_WIDTH-1:0]     memory_addr_in;
    wire [ADDR_WIDTH-1:0]     memory_addr_out;
    wire [DATA_WIDTH-1:0]     memory_data_in_real;
    wire [DATA_WIDTH-1:0]     memory_data_in_imag;
    wire [DATA_WIDTH-1:0]     memory_data_out_real;
    wire [DATA_WIDTH-1:0]     memory_data_out_imag;
    
    // Instantiate controller
    fft_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .FFT_POINTS(FFT_POINTS),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) controller_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .data_valid(data_valid),
        .data_in_real(data_in_real),
        .data_in_imag(data_in_imag),
        .addr_in(addr_in),
        .rd_en(rd_en),
        .addr_out(addr_out),
        .memory_data_out_real(memory_data_out_real),
        .memory_data_out_imag(memory_data_out_imag),
        
        .busy(busy),
        .done(done),
        .memory_we(memory_we),
        .memory_addr_in(memory_addr_in),
        .memory_addr_out(memory_addr_out),
        .memory_data_in_real(memory_data_in_real),
        .memory_data_in_imag(memory_data_in_imag),
        .data_out_real(data_out_real),
        .data_out_imag(data_out_imag)
    );
    
    // Instantiate data memory
    fft_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .FFT_POINTS(FFT_POINTS),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) memory_inst (
        .clk(clk),
        .we(memory_we),
        .addr_in(memory_addr_in),
        .addr_out(memory_addr_out),
        .data_in_real(memory_data_in_real),
        .data_in_imag(memory_data_in_imag),
        .data_out_real(memory_data_out_real),
        .data_out_imag(memory_data_out_imag)
    );
    
endmodule