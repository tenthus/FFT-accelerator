/**
 * Fast Fourier Transform Accelerator - Butterfly Unit
 * 
 * This module implements the butterfly operation, which is the core
 * computation of the FFT algorithm. It performs the following operations:
 * A' = A + B*W
 * B' = A - B*W
 * Where W is the twiddle factor.
 */
 module fft_butterfly #(
    parameter DATA_WIDTH = 16     // Width of data samples
)(
    input                      clk,            // System clock
    input                      rst_n,          // Active low reset
    input                      en,             // Enable butterfly computation
    
    input  [DATA_WIDTH-1:0]    data_a_real,    // Input A (real part)
    input  [DATA_WIDTH-1:0]    data_a_imag,    // Input A (imaginary part)
    input  [DATA_WIDTH-1:0]    data_b_real,    // Input B (real part)
    input  [DATA_WIDTH-1:0]    data_b_imag,    // Input B (imaginary part)
    input  [DATA_WIDTH-1:0]    twiddle_real,   // Twiddle factor (real part)
    input  [DATA_WIDTH-1:0]    twiddle_imag,   // Twiddle factor (imaginary part)
    
    output [DATA_WIDTH-1:0]    out_a_real,     // Output A (real part)
    output [DATA_WIDTH-1:0]    out_a_imag,     // Output A (imaginary part)
    output [DATA_WIDTH-1:0]    out_b_real,     // Output B (real part)
    output [DATA_WIDTH-1:0]    out_b_imag      // Output B (imaginary part)
);

    // Fixed-point format:
    // 1 bit sign, DATA_WIDTH-1 bits fractional part (Q1.DATA_WIDTH-1)
    localparam FRAC_BITS = DATA_WIDTH - 1;
    
    // Internal signals
    reg [DATA_WIDTH-1:0]    out_a_real_reg;
    reg [DATA_WIDTH-1:0]    out_a_imag_reg;
    reg [DATA_WIDTH-1:0]    out_b_real_reg;
    reg [DATA_WIDTH-1:0]    out_b_imag_reg;
    
    // Temporary signals for complex multiplication and addition/subtraction
    reg  [2*DATA_WIDTH-1:0] mult_temp_real;
    reg  [2*DATA_WIDTH-1:0] mult_temp_imag;
    wire [DATA_WIDTH-1:0]   b_twiddle_real;
    wire [DATA_WIDTH-1:0]   b_twiddle_imag;
    
    // Assign the outputs
    assign out_a_real = out_a_real_reg;
    assign out_a_imag = out_a_imag_reg;
    assign out_b_real = out_b_real_reg;
    assign out_b_imag = out_b_imag_reg;
    
    // Calculate B*W (complex multiplication)
    // (a + bi)(c + di) = (ac - bd) + (ad + bc)i
    always @(*) begin
        // Real part = data_b_real * twiddle_real - data_b_imag * twiddle_imag
        mult_temp_real = ($signed(data_b_real) * $signed(twiddle_real) - 
                          $signed(data_b_imag) * $signed(twiddle_imag)) >>> FRAC_BITS;
        
        // Imaginary part = data_b_real * twiddle_imag + data_b_imag * twiddle_real
        mult_temp_imag = ($signed(data_b_real) * $signed(twiddle_imag) + 
                          $signed(data_b_imag) * $signed(twiddle_real)) >>> FRAC_BITS;
    end
    
    // Convert from 2*DATA_WIDTH to DATA_WIDTH with saturation
    function [DATA_WIDTH-1:0] saturate;
        input [2*DATA_WIDTH-1:0] value;
        begin
            // Check for positive overflow
            if (value[2*DATA_WIDTH-1] == 0 && |value[2*DATA_WIDTH-2:DATA_WIDTH-1] != 0) begin
                saturate = {1'b0, {(DATA_WIDTH-1){1'b1}}}; // Max positive value
            end
            // Check for negative overflow
            else if (value[2*DATA_WIDTH-1] == 1 && &value[2*DATA_WIDTH-2:DATA_WIDTH-1] != 1) begin
                saturate = {1'b1, {(DATA_WIDTH-1){1'b0}}}; // Max negative value
            end
            // No overflow, just take the lower DATA_WIDTH bits
            else begin
                saturate = value[DATA_WIDTH-1:0];
            end
        end
    endfunction
    
    // B*W with saturation
    assign b_twiddle_real = saturate(mult_temp_real);
    assign b_twiddle_imag = saturate(mult_temp_imag);
    
    // Butterfly computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_a_real_reg <= 0;
            out_a_imag_reg <= 0;
            out_b_real_reg <= 0;
            out_b_imag_reg <= 0;
        end else if (en) begin
            // A' = A + B*W
            out_a_real_reg <= $signed(data_a_real) + $signed(b_twiddle_real);
            out_a_imag_reg <= $signed(data_a_imag) + $signed(b_twiddle_imag);
            
            // B' = A - B*W
            out_b_real_reg <= $signed(data_a_real) - $signed(b_twiddle_real);
            out_b_imag_reg <= $signed(data_a_imag) - $signed(b_twiddle_imag);
        end
    end
    
endmodule