/**
 * Fast Fourier Transform Accelerator - Dual-Port Memory
 * 
 * This module implements a dual-port memory to store FFT data.
 * It allows simultaneous read and write operations.
 */
 module fft_memory #(
    parameter DATA_WIDTH = 16,     // Width of data samples
    parameter FFT_POINTS = 64,     // Number of FFT points
    parameter ADDR_WIDTH = 6       // log2(FFT_POINTS)
)(
    input                      clk,           // System clock
    input                      we,            // Write enable
    input  [ADDR_WIDTH-1:0]    addr_in,       // Write address
    input  [ADDR_WIDTH-1:0]    addr_out,      // Read address
    input  [DATA_WIDTH-1:0]    data_in_real,  // Input data (real part)
    input  [DATA_WIDTH-1:0]    data_in_imag,  // Input data (imaginary part)
    
    output [DATA_WIDTH-1:0]    data_out_real, // Output data (real part)
    output [DATA_WIDTH-1:0]    data_out_imag  // Output data (imaginary part)
);

    // Memory arrays for real and imaginary parts
    reg [DATA_WIDTH-1:0] mem_real [0:FFT_POINTS-1];
    reg [DATA_WIDTH-1:0] mem_imag [0:FFT_POINTS-1];
    
    // Output registers
    reg [DATA_WIDTH-1:0] data_out_real_reg;
    reg [DATA_WIDTH-1:0] data_out_imag_reg;
    
    // Write operation
    always @(posedge clk) begin
        if (we) begin
            mem_real[addr_in] <= data_in_real;
            mem_imag[addr_in] <= data_in_imag;
        end
    end
    
    // Read operation
    always @(posedge clk) begin
        data_out_real_reg <= mem_real[addr_out];
        data_out_imag_reg <= mem_imag[addr_out];
    end
    
    // Output assignment
    assign data_out_real = data_out_real_reg;
    assign data_out_imag = data_out_imag_reg;
    
    // Initialize memory to zeros (for simulation)
    integer i;
    initial begin
        for (i = 0; i < FFT_POINTS; i = i + 1) begin
            mem_real[i] = 0;
            mem_imag[i] = 0;
        end
    end
    
endmodule