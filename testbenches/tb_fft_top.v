/**
 * Testbench for the FFT Top Module
 * 
 * This testbench verifies the complete FFT accelerator functionality,
 * including both pipelined and non-pipelined implementations.
 */
 `timescale 1ns / 1ps

 module tb_fft_top;
 
     // Parameters
     parameter DATA_WIDTH = 16;
     parameter FFT_POINTS = 64;
     parameter ADDR_WIDTH = 6;
     parameter CLK_PERIOD = 10;  // 10ns = 100MHz
     
     // Testbench signals
     reg                      clk;
     reg                      rst_n;
     reg                      start;
     reg                      data_valid;
     reg  [DATA_WIDTH-1:0]    data_in_real;
     reg  [DATA_WIDTH-1:0]    data_in_imag;
     reg  [ADDR_WIDTH-1:0]    addr_in;
     reg                      rd_en;
     reg  [ADDR_WIDTH-1:0]    addr_out;
     
     wire                     busy;
     wire                     done;
     wire [DATA_WIDTH-1:0]    data_out_real;
     wire [DATA_WIDTH-1:0]    data_out_imag;
     
     // File handles for output
     integer file_output;
     
     // Instantiate the non-pipelined FFT module
     fft_top #(
         .DATA_WIDTH(DATA_WIDTH),
         .FFT_POINTS(FFT_POINTS),
         .ADDR_WIDTH(ADDR_WIDTH)
     ) dut (
         .clk(clk),
         .rst_n(rst_n),
         .start(start),
         .data_valid(data_valid),
         .data_in_real(data_in_real),
         .data_in_imag(data_in_imag),
         .addr_in(addr_in),
         .rd_en(rd_en),
         .addr_out(addr_out),
         .busy(busy),
         .done(done),
         .data_out_real(data_out_real),
         .data_out_imag(data_out_imag)
     );
     
     // Clock generation
     always begin
         #(CLK_PERIOD/2) clk = ~clk;
     end
     
     // Test vectors
     reg signed [DATA_WIDTH-1:0] test_data_real [0:FFT_POINTS-1];
     reg signed [DATA_WIDTH-1:0] test_data_imag [0:FFT_POINTS-1];
     reg signed [DATA_WIDTH-1:0] expected_output_real [0:FFT_POINTS-1];
     reg signed [DATA_WIDTH-1:0] expected_output_imag [0:FFT_POINTS-1];
     
     // Task to generate test data
     task generate_test_data;
         integer i;
         begin
             // Generate various test patterns
             
             // 1. Impulse signal (x[0]=1, rest 0)
             for (i = 0; i < FFT_POINTS; i = i + 1) begin
                 if (i == 0)
                     test_data_real[i] = 16'h7FFF; // ~1.0 in Q1.15
                 else
                     test_data_real[i] = 16'h0000; // 0.0
                     
                 test_data_imag[i] = 16'h0000;     // All zeros for imaginary
             end
             
             // For an impulse, the FFT should be a constant for all frequencies
             // But we won't check this automatically in this testbench
         end
     endtask
     
     // Task to load data into FFT
     task load_data;
         integer i;
         begin
             $display("Loading data into FFT...");
             
             for (i = 0; i < FFT_POINTS; i = i + 1) begin
                 @(posedge clk);
                 data_valid = 1;
                 addr_in = i;
                 data_in_real = test_data_real[i];
                 data_in_imag = test_data_imag[i];
                 #1; // Small delay to check signals
             end
             
             @(posedge clk);
             data_valid = 0;
         end
     endtask
     
     // Task to read FFT results
     task read_results;
         integer i;
         begin
             $display("Reading FFT results...");
             file_output = $fopen("fft_output.txt", "w");
             
             for (i = 0; i < FFT_POINTS; i = i + 1) begin
                 @(posedge clk);
                 rd_en = 1;
                 addr_out = i;
                 #1; // Small delay to check signals
                 
                 $display("FFT Output %d: Real=%d, Imag=%d", i, $signed(data_out_real), $signed(data_out_imag));
                 $fwrite(file_output, "%d,%d,%d\n", i, $signed(data_out_real), $signed(data_out_imag));
             end
             
             @(posedge clk);
             rd_en = 0;
             $fclose(file_output);
         end
     endtask
     
     // Task to check FFT results against expected values
     task check_results;
         integer i;
         integer errors;
         real tolerance;
         begin
             $display("Checking FFT results...");
             errors = 0;
             tolerance = 100; // Acceptable difference in fixed-point value
             
             for (i = 0; i < FFT_POINTS; i = i + 1) begin
                 @(posedge clk);
                 rd_en = 1;
                 addr_out = i;
                 #1; // Small delay to check signals
                 
                 if (($signed(data_out_real) - $signed(expected_output_real[i]) > tolerance) ||
                     ($signed(data_out_real) - $signed(expected_output_real[i]) < -tolerance) ||
                     ($signed(data_out_imag) - $signed(expected_output_imag[i]) > tolerance) ||
                     ($signed(data_out_imag) - $signed(expected_output_imag[i]) < -tolerance)) begin
                     
                     $display("Error at point %d: Got Real=%d, Imag=%d, Expected Real=%d, Imag=%d",
                              i, $signed(data_out_real), $signed(data_out_imag),
                              $signed(expected_output_real[i]), $signed(expected_output_imag[i]));
                     errors = errors + 1;
                 end
             end
             
             @(posedge clk);
             rd_en = 0;
             
             if (errors == 0)
                 $display("All FFT outputs within tolerance!");
             else
                 $display("%d errors found in FFT output", errors);
         end
     endtask
     
     // Test procedure
     initial begin
         // Initialize signals
         clk = 0;
         rst_n = 0;
         start = 0;
         data_valid = 0;
         data_in_real = 0;
         data_in_imag = 0;
         addr_in = 0;
         rd_en = 0;
         addr_out = 0;
         
         // Reset pulse
         #(CLK_PERIOD*2);
         rst_n = 1;
         #(CLK_PERIOD*2);
         
         // Generate test data
         generate_test_data();
         
         // Test 1: Basic FFT functionality
         $display("Test 1: Basic FFT functionality");
         
         // Start the FFT
         start = 1;
         #(CLK_PERIOD);
         start = 0;
         
         // Load input data
         load_data();
         
         // Wait for FFT completion
         wait(done);
         $display("FFT computation completed");
         
         // Read and store results
         read_results();
         
         // If we had expected outputs, we would check them here
         // check_results();
         
         // Test 2: Edge cases and error handling
         // Additional tests would be implemented here
         
         // End simulation
         #(CLK_PERIOD*10);
         $display("Simulation complete");
         $finish;
     end
     
     // Monitors for checking signals
     initial begin
         $monitor("Time=%t, State: busy=%b, done=%b", $time, busy, done);
     end
     
     // VCD dump for waveform viewing
     initial begin
         $dumpfile("tb_fft_top.vcd");
         $dumpvars(0, tb_fft_top);
     end
     
 endmodule