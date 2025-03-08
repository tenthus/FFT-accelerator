/**
 * Testbench for the FFT Butterfly Unit
 * 
 * This testbench verifies the functionality of the butterfly unit,
 * which is the core computational element of the FFT.
 */
 `timescale 1ns / 1ps

 module tb_butterfly_unit;
 
     // Parameters
     parameter DATA_WIDTH = 16;   // Q1.15 format
     parameter CLK_PERIOD = 10;   // 10ns = 100MHz
     
     // Testbench signals
     reg                       clk;
     reg                       rst_n;
     reg                       en;
     reg  [DATA_WIDTH-1:0]     data_a_real;
     reg  [DATA_WIDTH-1:0]     data_a_imag;
     reg  [DATA_WIDTH-1:0]     data_b_real;
     reg  [DATA_WIDTH-1:0]     data_b_imag;
     reg  [DATA_WIDTH-1:0]     twiddle_real;
     reg  [DATA_WIDTH-1:0]     twiddle_imag;
     
     wire [DATA_WIDTH-1:0]     out_a_real;
     wire [DATA_WIDTH-1:0]     out_a_imag;
     wire [DATA_WIDTH-1:0]     out_b_real;
     wire [DATA_WIDTH-1:0]     out_b_imag;
     
     // File handles
     integer file_output;
     
     // Instantiate the butterfly unit
     fft_butterfly #(
         .DATA_WIDTH(DATA_WIDTH)
     ) dut (
         .clk(clk),
         .rst_n(rst_n),
         .en(en),
         .data_a_real(data_a_real),
         .data_a_imag(data_a_imag),
         .data_b_real(data_b_real),
         .data_b_imag(data_b_imag),
         .twiddle_real(twiddle_real),
         .twiddle_imag(twiddle_imag),
         .out_a_real(out_a_real),
         .out_a_imag(out_a_imag),
         .out_b_real(out_b_real),
         .out_b_imag(out_b_imag)
     );
     
     // Clock generation
     always begin
         #(CLK_PERIOD/2) clk = ~clk;
     end
     
     // Test vectors - these are complex numbers in Q1.15 fixed-point format
     // A = 1.0 + 0.0i  -> 16'h7FFF, 16'h0000
     // B = 0.5 + 0.5i  -> 16'h4000, 16'h4000
     // W = 0.7071 - 0.7071i (W_8^1) -> 16'h5A82, 16'hA57E
     
     // Expected results for A' = A + B*W and B' = A - B*W with the above inputs
     // B*W = (0.5*0.7071 - 0.5*(-0.7071)) + (0.5*(-0.7071) + 0.5*0.7071)i = 0.7071 + 0.0i
     // A' = 1.0 + 0.0i + 0.7071 + 0.0i = 1.7071 + 0.0i
     // B' = 1.0 + 0.0i - 0.7071 - 0.0i = 0.2929 + 0.0i
     
     // Test procedure
     initial begin
         // Initialize signals
         clk = 0;
         rst_n = 0;
         en = 0;
         data_a_real = 0;
         data_a_imag = 0;
         data_b_real = 0;
         data_b_imag = 0;
         twiddle_real = 0;
         twiddle_imag = 0;
         
         // Open output file
         file_output = $fopen("butterfly_output.txt", "w");
         
         // Reset pulse
         #(CLK_PERIOD*2);
         rst_n = 1;
         #(CLK_PERIOD*2);
         
         // Test Case 1: Basic butterfly operation
         $display("Test Case 1: Basic Butterfly Operation");
         
         // Set inputs
         data_a_real = 16'h7FFF;  // 1.0
         data_a_imag = 16'h0000;  // 0.0
         data_b_real = 16'h4000;  // 0.5
         data_b_imag = 16'h4000;  // 0.5
         twiddle_real = 16'h5A82; // 0.7071
         twiddle_imag = 16'hA57E; // -0.7071
         
         // Enable butterfly computation
         en = 1;
         @(posedge clk);
         en = 0;
         
         // Wait for result
         @(posedge clk);
         
         // Display and log results
         $display("Input A: %h + %hi", data_a_real, data_a_imag);
         $display("Input B: %h + %hi", data_b_real, data_b_imag);
         $display("Twiddle: %h + %hi", twiddle_real, twiddle_imag);
         $display("Output A': %h + %hi", out_a_real, out_a_imag);
         $display("Output B': %h + %hi", out_b_real, out_b_imag);
         
         $fwrite(file_output, "Test Case 1: Basic Butterfly Operation\n");
         $fwrite(file_output, "Input A: %h + %hi\n", data_a_real, data_a_imag);
         $fwrite(file_output, "Input B: %h + %hi\n", data_b_real, data_b_imag);
         $fwrite(file_output, "Twiddle: %h + %hi\n", twiddle_real, twiddle_imag);
         $fwrite(file_output, "Output A': %h + %hi\n", out_a_real, out_a_imag);
         $fwrite(file_output, "Output B': %h + %hi\n\n", out_b_real, out_b_imag);
         
         // Test Case 2: W = 1 + 0i (First stage of FFT)
         $display("\nTest Case 2: W = 1 + 0i (First stage of FFT)");
         
         // Set inputs
         data_a_real = 16'h4000;  // 0.5
         data_a_imag = 16'h0000;  // 0.0
         data_b_real = 16'h2000;  // 0.25
         data_b_imag = 16'h0000;  // 0.0
         twiddle_real = 16'h7FFF; // 1.0
         twiddle_imag = 16'h0000; // 0.0
         
         // Enable butterfly computation
         en = 1;
         @(posedge clk);
         en = 0;
         
         // Wait for result
         @(posedge clk);
         
         // Display and log results
         $display("Input A: %h + %hi", data_a_real, data_a_imag);
         $display("Input B: %h + %hi", data_b_real, data_b_imag);
         $display("Twiddle: %h + %hi", twiddle_real, twiddle_imag);
         $display("Output A': %h + %hi", out_a_real, out_a_imag);
         $display("Output B': %h + %hi", out_b_real, out_b_imag);
         
         $fwrite(file_output, "Test Case 2: W = 1 + 0i (First stage of FFT)\n");
         $fwrite(file_output, "Input A: %h + %hi\n", data_a_real, data_a_imag);
         $fwrite(file_output, "Input B: %h + %hi\n", data_b_real, data_b_imag);
         $fwrite(file_output, "Twiddle: %h + %hi\n", twiddle_real, twiddle_imag);
         $fwrite(file_output, "Output A': %h + %hi\n", out_a_real, out_a_imag);
         $fwrite(file_output, "Output B': %h + %hi\n\n", out_b_real, out_b_imag);
         
         // Test Case 3: Complex inputs and twiddle factor
         $display("\nTest Case 3: Complex inputs and twiddle factor");
         
         // Set inputs
         data_a_real = 16'h4000;  // 0.5
         data_a_imag = 16'h2000;  // 0.25
         data_b_real = 16'h1000;  // 0.125
         data_b_imag = 16'h0800;  // 0.0625
         twiddle_real = 16'h0000; // 0.0
         twiddle_imag = 16'h8000; // -1.0
         
         // Enable butterfly computation
         en = 1;
         @(posedge clk);
         en = 0;
         
         // Wait for result
         @(posedge clk);
         
         // Display and log results
         $display("Input A: %h + %hi", data_a_real, data_a_imag);
         $display("Input B: %h + %hi", data_b_real, data_b_imag);
         $display("Twiddle: %h + %hi", twiddle_real, twiddle_imag);
         $display("Output A': %h + %hi", out_a_real, out_a_imag);
         $display("Output B': %h + %hi", out_b_real, out_b_imag);
         
         $fwrite(file_output, "Test Case 3: Complex inputs and twiddle factor\n");
         $fwrite(file_output, "Input A: %h + %hi\n", data_a_real, data_a_imag);
         $fwrite(file_output, "Input B: %h + %hi\n", data_b_real, data_b_imag);
         $fwrite(file_output, "Twiddle: %h + %hi\n", twiddle_real, twiddle_imag);
         $fwrite(file_output, "Output A': %h + %hi\n", out_a_real, out_a_imag);
         $fwrite(file_output, "Output B': %h + %hi\n\n", out_b_real, out_b_imag);
         
         // Test Case 4: Overflow test
         $display("\nTest Case 4: Overflow test");
         
         // Set inputs with values that could cause overflow
         data_a_real = 16'h7F00;  // Near maximum positive
         data_a_imag = 16'h7F00;  // Near maximum positive
         data_b_real = 16'h7F00;  // Near maximum positive
         data_b_imag = 16'h7F00;  // Near maximum positive
         twiddle_real = 16'h7F00; // Near maximum positive
         twiddle_imag = 16'h7F00; // Near maximum positive
         
         // Enable butterfly computation
         en = 1;
         @(posedge clk);
         en = 0;
         
         // Wait for result
         @(posedge clk);
         
         // Display and log results
         $display("Input A: %h + %hi", data_a_real, data_a_imag);
         $display("Input B: %h + %hi", data_b_real, data_b_imag);
         $display("Twiddle: %h + %hi", twiddle_real, twiddle_imag);
         $display("Output A': %h + %hi", out_a_real, out_a_imag);
         $display("Output B': %h + %hi", out_b_real, out_b_imag);
         
         $fwrite(file_output, "Test Case 4: Overflow test\n");
         $fwrite(file_output, "Input A: %h + %hi\n", data_a_real, data_a_imag);
         $fwrite(file_output, "Input B: %h + %hi\n", data_b_real, data_b_imag);
         $fwrite(file_output, "Twiddle: %h + %hi\n", twiddle_real, twiddle_imag);
         $fwrite(file_output, "Output A': %h + %hi\n", out_a_real, out_a_imag);
         $fwrite(file_output, "Output B': %h + %hi\n\n", out_b_real, out_b_imag);
         
         // Close output file
         $fclose(file_output);
         
         // End simulation
         #(CLK_PERIOD*10);
         $display("Simulation complete");
         $finish;
     end
     
     // VCD dump for waveform viewing
     initial begin
         $dumpfile("tb_butterfly_unit.vcd");
         $dumpvars(0, tb_butterfly_unit);
     end
     
 endmodule