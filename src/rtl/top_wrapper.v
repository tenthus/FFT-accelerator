/**
 * Fast Fourier Transform Accelerator - Top Wrapper
 * 
 * This module provides a simple wrapper to adapt the FFT accelerator
 * to the pins available on a specific FPGA board.
 * 
 * This example is tailored for an IceStick board but can be easily
 * adapted to other boards supported by Apio.
 */
 module top_wrapper (
    input        clk,           // Clock input (12 MHz on IceStick)
    input  [3:0] btn,           // Buttons (if available) or could be repurposed from GPIO
    output [4:0] led,           // LEDs on the board
    input  [7:0] gpio_in,       // GPIO pins for input
    output [7:0] gpio_out       // GPIO pins for output
);

    // Parameters
    parameter DATA_WIDTH = 16;
    parameter FFT_POINTS = 64;
    parameter ADDR_WIDTH = 6;
    
    // Internal signals
    wire rst_n;
    wire start;
    wire data_valid;
    reg [DATA_WIDTH-1:0] data_in_real;
    reg [DATA_WIDTH-1:0] data_in_imag;
    wire busy;
    wire done;
    wire data_out_valid;
    wire [DATA_WIDTH-1:0] data_out_real;
    wire [DATA_WIDTH-1:0] data_out_imag;
    
    // Control registers
    reg [ADDR_WIDTH-1:0] sample_counter;
    reg [2:0] state;
    
    localparam IDLE = 3'd0;
    localparam LOAD = 3'd1;
    localparam PROCESS = 3'd2;
    localparam OUTPUT = 3'd3;
    
    // Map external signals to internal ones
    assign rst_n = ~btn[0];          // Reset button (active low)
    assign start = btn[1];           // Start button
    assign data_valid = (state == LOAD) && (sample_counter < FFT_POINTS);
    
    // LED outputs
    assign led[0] = busy;            // FFT busy
    assign led[1] = done;            // FFT done
    assign led[2] = data_out_valid;  // Output valid
    assign led[3] = (state == LOAD); // Loading state
    assign led[4] = (state == OUTPUT); // Output state
    
    // GPIO outputs
    // Here we're just assigning some internal signals to outputs for debugging
    // In a real application, these would be connected to a proper data interface
    assign gpio_out = data_out_valid ? data_out_real[7:0] : 8'h00;
    
    // Simple state machine for demo
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            sample_counter <= 0;
            data_in_real <= 0;
            data_in_imag <= 0;
        end else begin
            case (state)
                IDLE: begin
                    sample_counter <= 0;
                    if (start) begin
                        state <= LOAD;
                    end
                end
                
                LOAD: begin
                    if (sample_counter < FFT_POINTS) begin
                        // Generate a test sine wave
                        // In a real application, data would come from external inputs
                        data_in_real <= (sample_counter < FFT_POINTS/2) ? 16'h2000 : 16'hE000;
                        data_in_imag <= 16'h0000;
                        
                        sample_counter <= sample_counter + 1;
                    end else begin
                        state <= PROCESS;
                    end
                end
                
                PROCESS: begin
                    if (done) begin
                        state <= OUTPUT;
                        sample_counter <= 0;
                    end
                end
                
                OUTPUT: begin
                    if (sample_counter >= FFT_POINTS || start) begin
                        state <= IDLE;
                    end else if (data_out_valid) begin
                        sample_counter <= sample_counter + 1;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Instantiate the pipelined FFT module
    // This is just an example - you can use either fft_top or fft_top_pipelined
    // depending on your resources and requirements
    fft_top_pipelined #(
        .DATA_WIDTH(DATA_WIDTH),
        .FFT_POINTS(FFT_POINTS),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fft_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(state == IDLE && start),
        .data_valid(data_valid),
        .data_in_real(data_in_real),
        .data_in_imag(data_in_imag),
        .busy(busy),
        .done(done),
        .data_out_valid(data_out_valid),
        .data_out_real(data_out_real),
        .data_out_imag(data_out_imag)
    );
    
endmodule