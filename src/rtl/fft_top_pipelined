/**
 * Fast Fourier Transform Accelerator - Pipelined Top Module
 * 
 * This module serves as an alternative top-level entity for the FFT accelerator,
 * using the pipelined FFT implementation.
 */
module fft_top_pipelined #(
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
    
    output                      busy,         // FFT computation in progress
    output                      done,         // FFT computation complete
    output                      data_out_valid, // Output data valid
    output [DATA_WIDTH-1:0]     data_out_real,// Output data (real part)
    output [DATA_WIDTH-1:0]     data_out_imag // Output data (imaginary part)
);

    // FSM states
    localparam IDLE = 2'd0;
    localparam PROCESS = 2'd1;
    localparam COMPLETE = 2'd2;
    
    // Internal registers
    reg [1:0] state;
    reg [1:0] next_state;
    reg [ADDR_WIDTH:0] sample_count;
    
    // Control signals
    reg pipeline_en;
    
    // FSM state transitions
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // FSM next state logic and output control
    always @(*) begin
        next_state = state;
        pipeline_en = 0;
        busy = 0;
        done = 0;
        
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = PROCESS;
                end
            end
            
            PROCESS: begin
                busy = 1;
                pipeline_en = 1;
                
                if (sample_count >= FFT_POINTS && !data_out_valid) begin
                    next_state = COMPLETE;
                end
            end
            
            COMPLETE: begin
                done = 1;
                
                if (!start) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Sample counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_count <= 0;
        end else if (state == IDLE) begin
            sample_count <= 0;
        end else if (state == PROCESS) begin
            if (data_valid) begin
                sample_count <= sample_count + 1;
            end
        end
    end
    
    // Instantiate the FFT pipeline
    fft_pipeline #(
        .DATA_WIDTH(DATA_WIDTH),
        .FFT_POINTS(FFT_POINTS)
    ) pipeline_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(pipeline_en),
        .data_valid(data_valid),
        .data_in_real(data_in_real),
        .data_in_imag(data_in_imag),
        .data_out_valid(data_out_valid),
        .data_out_real(data_out_real),
        .data_out_imag(data_out_imag)
    );
    
endmodule