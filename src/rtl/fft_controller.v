/**
 * Fast Fourier Transform Accelerator - Controller Module
 * 
 * This module manages the control flow of the FFT computation,
 * orchestrating data loading, butterfly operations, and result retrieval.
 */
 module fft_controller #(
    parameter DATA_WIDTH = 16,     // Width of data samples
    parameter FFT_POINTS = 64,     // Number of FFT points (must be power of 2)
    parameter ADDR_WIDTH = 6       // log2(FFT_POINTS)
)(
    input                       clk,              // System clock
    input                       rst_n,            // Active low reset
    input                       start,            // Start FFT computation
    input                       data_valid,       // Input data valid
    input  [DATA_WIDTH-1:0]     data_in_real,     // Input data (real part)
    input  [DATA_WIDTH-1:0]     data_in_imag,     // Input data (imaginary part)
    input  [ADDR_WIDTH-1:0]     addr_in,          // Input data address
    input                       rd_en,            // Read enable
    input  [ADDR_WIDTH-1:0]     addr_out,         // Output data address
    input  [DATA_WIDTH-1:0]     memory_data_out_real, // Data from memory (real)
    input  [DATA_WIDTH-1:0]     memory_data_out_imag, // Data from memory (imag)
    
    output reg                  busy,             // FFT computation in progress
    output reg                  done,             // FFT computation complete
    output reg                  memory_we,        // Memory write enable
    output reg [ADDR_WIDTH-1:0] memory_addr_in,   // Memory write address
    output reg [ADDR_WIDTH-1:0] memory_addr_out,  // Memory read address
    output reg [DATA_WIDTH-1:0] memory_data_in_real, // Data to memory (real)
    output reg [DATA_WIDTH-1:0] memory_data_in_imag, // Data to memory (imag)
    output reg [DATA_WIDTH-1:0] data_out_real,    // Output data (real part)
    output reg [DATA_WIDTH-1:0] data_out_imag     // Output data (imaginary part)
);

    // FSM states
    localparam IDLE = 3'd0;
    localparam LOAD = 3'd1;
    localparam COMPUTE = 3'd2;
    localparam REORDER = 3'd3;
    localparam OUTPUT = 3'd4;

    // Twiddle factor ROM size
    localparam TWIDDLE_SIZE = FFT_POINTS/2;
    
    // Internal registers
    reg [2:0]               state;
    reg [2:0]               next_state;
    reg [ADDR_WIDTH-1:0]    stage;
    reg [ADDR_WIDTH-1:0]    butterfly_count;
    reg [ADDR_WIDTH:0]      distance;
    
    // Butterfly operation signals
    reg                     butterfly_en;
    reg [ADDR_WIDTH-1:0]    butterfly_addr_a;
    reg [ADDR_WIDTH-1:0]    butterfly_addr_b;
    reg [ADDR_WIDTH-1:0]    twiddle_addr;
    wire [DATA_WIDTH-1:0]   butterfly_out_a_real;
    wire [DATA_WIDTH-1:0]   butterfly_out_a_imag;
    wire [DATA_WIDTH-1:0]   butterfly_out_b_real;
    wire [DATA_WIDTH-1:0]   butterfly_out_b_imag;
    wire [DATA_WIDTH-1:0]   twiddle_real;
    wire [DATA_WIDTH-1:0]   twiddle_imag;
    
    // Butterfly input data registers
    reg [DATA_WIDTH-1:0]    data_a_real;
    reg [DATA_WIDTH-1:0]    data_a_imag;
    reg [DATA_WIDTH-1:0]    data_b_real;
    reg [DATA_WIDTH-1:0]    data_b_imag;
    
    // Bit-reverse counter for reordering
    reg [ADDR_WIDTH-1:0]    src_addr;
    reg [ADDR_WIDTH-1:0]    dst_addr;
    reg                     reorder_we;
    
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
        .en(butterfly_en),
        .data_a_real(data_a_real),
        .data_a_imag(data_a_imag),
        .data_b_real(data_b_real),
        .data_b_imag(data_b_imag),
        .twiddle_real(twiddle_real),
        .twiddle_imag(twiddle_imag),
        .out_a_real(butterfly_out_a_real),
        .out_a_imag(butterfly_out_a_imag),
        .out_b_real(butterfly_out_b_real),
        .out_b_imag(butterfly_out_b_imag)
    );
    
    // Bit-reverse function
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
    
    // FSM state transitions
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // FSM next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = LOAD;
                end
            end
            
            LOAD: begin
                if (!data_valid && busy) begin
                    next_state = COMPUTE;
                end
            end
            
            COMPUTE: begin
                if (stage == ADDR_WIDTH) begin
                    next_state = REORDER;
                end
            end
            
            REORDER: begin
                if (src_addr == FFT_POINTS-1) begin
                    next_state = OUTPUT;
                end
            end
            
            OUTPUT: begin
                if (!rd_en && done) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Control signals and datapath
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers
            busy <= 0;
            done <= 0;
            memory_we <= 0;
            memory_addr_in <= 0;
            memory_addr_out <= 0;
            memory_data_in_real <= 0;
            memory_data_in_imag <= 0;
            data_out_real <= 0;
            data_out_imag <= 0;
            stage <= 0;
            butterfly_count <= 0;
            distance <= 0;
            butterfly_en <= 0;
            butterfly_addr_a <= 0;
            butterfly_addr_b <= 0;
            twiddle_addr <= 0;
            data_a_real <= 0;
            data_a_imag <= 0;
            data_b_real <= 0;
            data_b_imag <= 0;
            src_addr <= 0;
            dst_addr <= 0;
            reorder_we <= 0;
        end else begin
            // Default values
            memory_we <= 0;
            butterfly_en <= 0;
            reorder_we <= 0;
            
            case (state)
                IDLE: begin
                    busy <= 0;
                    done <= 0;
                    stage <= 0;
                    butterfly_count <= 0;
                    distance <= 1;
                    src_addr <= 0;
                    
                    if (start) begin
                        busy <= 1;
                    end
                end
                
                LOAD: begin
                    if (data_valid) begin
                        memory_we <= 1;
                        memory_addr_in <= addr_in;
                        memory_data_in_real <= data_in_real;
                        memory_data_in_imag <= data_in_imag;
                    end
                end
                
                COMPUTE: begin
                    // Butterfly computation state machine
                    case (butterfly_count[1:0])
                        2'd0: begin
                            // Setup read addresses for first point
                            memory_addr_out <= butterfly_addr_a;
                            butterfly_count <= butterfly_count + 1;
                        end
                        
                        2'd1: begin
                            // Latch data for first point and set address for second point
                            data_a_real <= memory_data_out_real;
                            data_a_imag <= memory_data_out_imag;
                            memory_addr_out <= butterfly_addr_b;
                            butterfly_count <= butterfly_count + 1;
                        end
                        
                        2'd2: begin
                            // Latch data for second point and enable butterfly
                            data_b_real <= memory_data_out_real;
                            data_b_imag <= memory_data_out_imag;
                            butterfly_en <= 1;
                            butterfly_count <= butterfly_count + 1;
                        end
                        
                        2'd3: begin
                            // Write results back to memory
                            memory_we <= 1;
                            memory_addr_in <= butterfly_addr_a;
                            memory_data_in_real <= butterfly_out_a_real;
                            memory_data_in_imag <= butterfly_out_a_imag;
                            
                            // Setup next butterfly
                            butterfly_count <= butterfly_count + 1;
                            
                            // Check if we need to advance to next butterfly pair
                            if (butterfly_count[ADDR_WIDTH:2] == (FFT_POINTS/2 - 1)) begin
                                // Last butterfly in this stage
                                butterfly_count <= 0;
                                stage <= stage + 1;
                                distance <= distance << 1;
                            end else if (butterfly_count[1:0] == 2'd3) begin
                                // Write second point in the next cycle
                                memory_we <= 0;
                            end
                        end
                    endcase
                    
                    // Delayed write for second point (to avoid memory collision)
                    if (butterfly_count[1:0] == 2'd0 && butterfly_count != 0) begin
                        memory_we <= 1;
                        memory_addr_in <= butterfly_addr_b;
                        memory_data_in_real <= butterfly_out_b_real;
                        memory_data_in_imag <= butterfly_out_b_imag;
                    end
                    
                    // Calculate butterfly addresses
                    if (butterfly_count[1:0] == 2'd3 || state != next_state) begin
                        butterfly_addr_a <= butterfly_count[ADDR_WIDTH:2] & (~(distance-1));
                        butterfly_addr_b <= butterfly_addr_a + distance;
                        twiddle_addr <= (butterfly_count[ADDR_WIDTH:2] & (distance-1)) * (FFT_POINTS/(2*distance));
                    end
                end
                
                REORDER: begin
                    // Bit-reverse permutation logic
                    case (src_addr[1:0])
                        2'd0: begin
                            // Setup read address
                            memory_addr_out <= src_addr;
                            src_addr <= src_addr + 1;
                        end
                        
                        2'd1: begin
                            // Compute bit-reversed destination
                            dst_addr <= bit_reverse(src_addr - 1);
                            memory_data_in_real <= memory_data_out_real;
                            memory_data_in_imag <= memory_data_out_imag;
                            src_addr <= src_addr + 1;
                        end
                        
                        2'd2: begin
                            // If source doesn't equal destination, write to new location
                            if ((src_addr - 2) != dst_addr) begin
                                memory_we <= 1;
                                memory_addr_in <= dst_addr;
                                // Data was latched in previous step
                            end
                            
                            // Setup read for next address
                            memory_addr_out <= src_addr;
                            src_addr <= src_addr + 1;
                        end
                        
                        2'd3: begin
                            // Compute bit-reversed destination
                            dst_addr <= bit_reverse(src_addr - 1);
                            memory_data_in_real <= memory_data_out_real;
                            memory_data_in_imag <= memory_data_out_imag;
                            src_addr <= src_addr + 1;
                        end
                    endcase
                    
                    // Delayed write for the previous cycle
                    if (src_addr[1:0] == 2'd0 && src_addr != 0) begin
                        if ((src_addr - 2) != dst_addr) begin
                            memory_we <= 1;
                            memory_addr_in <= dst_addr;
                            // Data was latched in previous step
                        end
                    end
                    
                    // Exit condition
                    if (next_state == OUTPUT) begin
                        done <= 1;
                    end
                end
                
                OUTPUT: begin
                    if (rd_en) begin
                        memory_addr_out <= addr_out;
                        data_out_real <= memory_data_out_real;
                        data_out_imag <= memory_data_out_imag;
                    end
                    
                    if (next_state == IDLE) begin
                        done <= 0;
                    end
                end
            endcase
        end
    end
    
endmodule