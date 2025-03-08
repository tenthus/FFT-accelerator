/**
 * Fast Fourier Transform Accelerator - FIFO Buffer Module
 * 
 * This module implements a First-In-First-Out buffer for the FFT pipeline.
 * It's used for implementing the delay elements in the FFT stages.
 */
 module fifo #(
    parameter DATA_WIDTH = 16,  // Width of data samples
    parameter DEPTH = 8         // FIFO depth
)(
    input                       clk,      // System clock
    input                       rst_n,    // Active low reset
    input                       wr_en,    // Write enable
    input                       rd_en,    // Read enable
    input  [DATA_WIDTH-1:0]     din,      // Data input
    
    output [DATA_WIDTH-1:0]     dout,     // Data output
    output                      empty,    // FIFO empty flag
    output                      full      // FIFO full flag
);

    // Local parameters
    localparam ADDR_WIDTH = $clog2(DEPTH);
    
    // Internal registers
    reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;
    reg [DATA_WIDTH-1:0] dout_reg;
    
    // Internal status signals
    wire [ADDR_WIDTH:0] wr_ptr_next;
    wire [ADDR_WIDTH:0] rd_ptr_next;
    wire [ADDR_WIDTH:0] wr_addr;
    wire [ADDR_WIDTH:0] rd_addr;
    
    // Status flags
    assign empty = (wr_ptr == rd_ptr);
    assign full = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && 
                  (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);
    
    // Address calculations
    assign wr_addr = wr_ptr[ADDR_WIDTH-1:0];
    assign rd_addr = rd_ptr[ADDR_WIDTH-1:0];
    assign wr_ptr_next = wr_ptr + 1;
    assign rd_ptr_next = rd_ptr + 1;
    
    // Write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            memory[wr_addr] <= din;
            wr_ptr <= wr_ptr_next;
        end
    end
    
    // Read operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            dout_reg <= 0;
        end else if (rd_en && !empty) begin
            dout_reg <= memory[rd_addr];
            rd_ptr <= rd_ptr_next;
        end
    end
    
    // Output assignment
    assign dout = dout_reg;
    
    // Initialize memory to zeros (for simulation)
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            memory[i] = 0;
        end
    end
    
endmodule