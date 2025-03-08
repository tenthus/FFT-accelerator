/**
 * Fast Fourier Transform Accelerator - Pipelined FFT Implementation
 * 
 * This module implements a pipelined FFT architecture.
 * It connects multiple FFT stages in sequence to form a pipeline.
 */
 module fft_pipeline #(
    parameter DATA_WIDTH = 16,     // Width of data samples
    parameter FFT_POINTS = 64      // Number of FFT points (must be power of 2)
)(
    input                          clk,           // System clock
    input                          rst_n,         // Active low reset
    input                          en,            // Enable pipeline
    input                          data_valid,    // Input data valid
    input  [DATA_WIDTH-1:0]        data_in_real,  // Input data (real part)
    input  [DATA_WIDTH-1:0]        data_in_imag,  // Input data (imaginary part)
    
    output                         data_out_valid,// Output data valid
    output [DATA_WIDTH-1:0]        data_out_real, // Output data (real part)
    output [DATA_WIDTH-1:0]        data_out_imag  // Output data (imaginary part)
);

    // Local parameters
    localparam ADDR_WIDTH = $clog2(FFT_POINTS);
    localparam NUM_STAGES = ADDR_WIDTH;
    
    // Bit reverse function for input reordering
    function [ADDR_WIDTH-1:0] bit_reverse;
        input [ADDR_WIDTH-1:0] addr;
        integer i;
        begin
            bit_reverse = 0;
            for (i = 0; i < ADDR_WIDTH; i = i + 1) begin
                bit_reverse[ADDR_WIDTH-1-i] = addr[i];
            end
        end
    endfunction
    
    // Internal signals
    reg [ADDR_WIDTH-1:0]     sample_counter;
    reg                      input_valid;
    wire                     stage_enable;
    
    // Valid signal propagation
    reg [NUM_STAGES:0]       valid_pipeline;
    
    // Stage interconnections
    wire [DATA_WIDTH-1:0]    stage_data_real [0:NUM_STAGES];
    wire [DATA_WIDTH-1:0]    stage_data_imag [0:NUM_STAGES];
    wire [ADDR_WIDTH-1:0]    stage_addr [0:NUM_STAGES];
    
    // Input sample counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_counter <= 0;
            input_valid <= 0;
        end else if (en) begin
            if (data_valid) begin
                if (sample_counter == FFT_POINTS-1) begin
                    sample_counter <= 0;
                end else begin
                    sample_counter <= sample_counter + 1;
                end
                input_valid <= 1;
            end else begin
                input_valid <= 0;
            end
        end
    end
    
    // Valid signal propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_pipeline <= 0;
        end else if (en) begin
            valid_pipeline <= {valid_pipeline[NUM_STAGES-1:0], input_valid};
        end
    end
    
    // Enable signal for stages
    assign stage_enable = en & (input_valid | |valid_pipeline[NUM_STAGES-1:0]);
    
    // Input to first stage (with bit reversal)
    assign stage_data_real[0] = data_in_real;
    assign stage_data_imag[0] = data_in_imag;
    assign stage_addr[0] = bit_reverse(sample_counter);
    
    // Generate FFT stages
    genvar i;
    generate
        for (i = 0; i < NUM_STAGES; i = i + 1) begin : fft_stages
            fft_stage #(
                .DATA_WIDTH(DATA_WIDTH),
                .STAGE_ID(i),
                .FFT_POINTS(FFT_POINTS)
            ) stage_inst (
                .clk(clk),
                .rst_n(rst_n),
                .en(stage_enable),
                .in_real(stage_data_real[i]),
                .in_imag(stage_data_imag[i]),
                .in_addr(stage_addr[i]),
                .out_real(stage_data_real[i+1]),
                .out_imag(stage_data_imag[i+1]),
                .out_addr(stage_addr[i+1])
            );
        end
    endgenerate
    
    // Output connections
    assign data_out_real = stage_data_real[NUM_STAGES];
    assign data_out_imag = stage_data_imag[NUM_STAGES];
    assign data_out_valid = valid_pipeline[NUM_STAGES];
    
endmodule