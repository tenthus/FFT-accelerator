/**
 * Fast Fourier Transform Accelerator - FFT Stage Module
 * 
 * This module implements a single stage of a pipelined FFT.
 * Each stage consists of a delay element and a butterfly unit.
 */
 module fft_stage #(
    parameter DATA_WIDTH = 16,     // Width of data samples
    parameter STAGE_ID = 0,        // Stage identifier (0 to log2(FFT_POINTS)-1)
    parameter FFT_POINTS = 64      // Number of FFT points
)(
    input                      clk,           // System clock
    input                      rst_n,         // Active low reset
    input                      en,            // Enable 
    input  [DATA_WIDTH-1:0]    in_real,       // Input data (real part)
    input  [DATA_WIDTH-1:0]    in_imag,       // Input data (imaginary part)
    input  [$clog2(FFT_POINTS)-1:0] in_addr,  // Input sample address
    
    output [DATA_WIDTH-1:0]    out_real,      // Output data (real part)
    output [DATA_WIDTH-1:0]    out_imag,      // Output data (imaginary part)
    output [$clog2(FFT_POINTS)-1:0] out_addr  // Output sample address
);

    // Local parameters
    localparam ADDR_WIDTH = $clog2(FFT_POINTS);
    localparam DELAY_DEPTH = 2**(ADDR_WIDTH-STAGE_ID-1);
    
    // Internal signals
    wire [DATA_WIDTH-1:0]    delay_real;
    wire [DATA_WIDTH-1:0]    delay_imag;
    wire [ADDR_WIDTH-1:0]    delay_addr;
    wire [DATA_WIDTH-1:0]    twiddle_real;
    wire [DATA_WIDTH-1:0]    twiddle_imag;
    wire [ADDR_WIDTH-1:0]    twiddle_addr;
    wire                     butterfly_enable;
    
    // Determine if inputs should go to upper or lower path
    wire path_select = in_addr[ADDR_WIDTH-STAGE_ID-1];
    
    // Determine the twiddle factor address for this butterfly
    assign twiddle_addr = in_addr[ADDR_WIDTH-STAGE_ID-2:0] << STAGE_ID;
    
    // Butterfly operation is enabled when we have a complete pair
    assign butterfly_enable = en & path_select;
    
    // Data and address for upper path
    wire [DATA_WIDTH-1:0] upper_real = path_select ? delay_real : in_real;
    wire [DATA_WIDTH-1:0] upper_imag = path_select ? delay_imag : in_imag;
    wire [ADDR_WIDTH-1:0] upper_addr = path_select ? delay_addr : in_addr;
    
    // Data for lower path
    wire [DATA_WIDTH-1:0] lower_real = path_select ? in_real : delay_real;
    wire [DATA_WIDTH-1:0] lower_imag = path_select ? in_imag : delay_imag;
    
    // Instantiate delay line for real part
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DELAY_DEPTH)
    ) delay_real_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(!path_select & en),
        .rd_en(path_select & en),
        .din(in_real),
        .dout(delay_real)
    );
    
    // Instantiate delay line for imaginary part
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DELAY_DEPTH)
    ) delay_imag_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(!path_select & en),
        .rd_en(path_select & en),
        .din(in_imag),
        .dout(delay_imag)
    );
    
    // Instantiate delay line for address
    fifo #(
        .DATA_WIDTH(ADDR_WIDTH),
        .DEPTH(DELAY_DEPTH)
    ) delay_addr_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(!path_select & en),
        .rd_en(path_select & en),
        .din(in_addr),
        .dout(delay_addr)
    );
    
    // Instantiate twiddle factor ROM
    fft_twiddle_rom #(
        .DATA_WIDTH(DATA_WIDTH),
        .FFT_POINTS(FFT_POINTS),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) twiddle_rom_inst (
        .clk(clk),
        .addr(twiddle_addr),
        .twiddle_real(twiddle_real),
        .twiddle_imag(twiddle_imag)
    );
    
    // Instantiate butterfly unit
    fft_butterfly #(
        .DATA_WIDTH(DATA_WIDTH)
    ) butterfly_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(butterfly_enable),
        .data_a_real(upper_real),
        .data_a_imag(upper_imag),
        .data_b_real(lower_real),
        .data_b_imag(lower_imag),
        .twiddle_real(twiddle_real),
        .twiddle_imag(twiddle_imag),
        .out_a_real(out_real),
        .out_a_imag(out_imag),
        .out_b_real(), // Not used in this implementation
        .out_b_imag()  // Not used in this implementation
    );
    
    // Output address is the same as the upper path address
    assign out_addr = upper_addr;
    
endmodule