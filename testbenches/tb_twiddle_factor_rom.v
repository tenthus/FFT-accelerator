/**
 * Testbench for the FFT Twiddle Factor ROM
 * 
 * This testbench verifies the correctness of the twiddle factors
 * stored in the ROM for FFT computation.
 */
 `timescale 1ns / 1ps

 module tb_twiddle_factor_rom;
 
     // Parameters
     parameter DATA_WIDTH = 16;     // Width of data samples
     parameter FFT_POINTS = 64;     // Number of FFT points
     parameter ADDR_WIDTH = 6;      // log2(FFT_POINTS)
     parameter CLK_PERIOD = 10;     // 10ns = 100MHz
     
     // Testbench signals
     reg                      clk;
     reg  [ADDR_WIDTH-1:0]    addr;
     
     wire [DATA_WIDTH-1:0]    twiddle_real;
     wire [DATA_WIDTH-1:0]    twiddle_imag;
     
     // File handle for output
     integer file_output;
     
     // Instantiate the twiddle factor ROM
     fft_twiddle_rom #(
         .DATA_WIDTH(DATA_WIDTH),
         .FFT_POINTS(FFT_POINTS),
         .ADDR_WIDTH(ADDR_WIDTH)
     ) dut (
         .clk(clk),
         .addr(addr),
         .twiddle_real(twiddle_real),
         .twiddle_imag(twiddle_imag)
     );
     
     // Clock generation
     always begin
         #(CLK_PERIOD/2) clk = ~clk;
     end
     
     // Helper function to convert fixed-point to floating-point
     function real fixed_to_float;
         input [DATA_WIDTH-1:0] fixed;
         begin
             // Convert from Q1.15 to float
             if (fixed[DATA_WIDTH-1] == 1) // Negative number
                 fixed_to_float = -1.0 * ((~fixed + 1) / 32768.0);
             else
                 fixed_to_float = fixed / 32768.0;
         end
     endfunction
     
     // Expected twiddle factors (based on FFT_POINTS=64)
     // W_N^k = cos(2*pi*k/N) - j*sin(2*pi*k/N)
     // We'll check some key values:
     // k=0: W_64^0 = 1 - j*0
     // k=16: W_64^16 = 0 - j*1
     // k=8: W_64^8 = 0.7071 - j*0.7071
     // k=24: W_64^24 = -0.7071 - j*0.7071
     
     // Test procedure
     initial begin
         // Initialize signals
         clk = 0;
         addr = 0;
         
         // Open output file
         file_output = $fopen("twiddle_factors.txt", "w");
         $fwrite(file_output, "addr,real,imag,real_float,imag_float\n");
         
         // Reset and wait a few cycles
         #(CLK_PERIOD*2);
         
         // Read all twiddle factors
         for (addr = 0; addr < FFT_POINTS/2; addr = addr + 1) begin
             @(posedge clk);
             #1; // Small delay to let outputs stabilize
             
             // Log the values
             $fwrite(file_output, "%d,%h,%h,%f,%f\n", 
                    addr, twiddle_real, twiddle_imag, 
                    fixed_to_float(twiddle_real), fixed_to_float(twiddle_imag));
         end
         
         // Close the file
         $fclose(file_output);
         
         // Now check specific values
         $display("Checking key twiddle factors...");
         
         // Check W_64^0
         addr = 0;
         @(posedge clk);
         #1;
         $display("W_%0d^%0d: %f%+fj (Expected: 1+0j)", 
                 FFT_POINTS, addr, fixed_to_float(twiddle_real), fixed_to_float(twiddle_imag));
         
         // Check W_64^16
         addr = 16;
         @(posedge clk);
         #1;
         $display("W_%0d^%0d: %f%+fj (Expected: 0-1j)", 
                 FFT_POINTS, addr, fixed_to_float(twiddle_real), fixed_to_float(twiddle_imag));
         
         // Check W_64^8
         addr = 8;
         @(posedge clk);
         #1;
         $display("W_%0d^%0d: %f%+fj (Expected: 0.7071-0.7071j)", 
                 FFT_POINTS, addr, fixed_to_float(twiddle_real), fixed_to_float(twiddle_imag));
         
         // Check W_64^24
         addr = 24;
         @(posedge clk);
         #1;
         $display("W_%0d^%0d: %f%+fj (Expected: -0.7071-0.7071j)", 
                 FFT_POINTS, addr, fixed_to_float(twiddle_real), fixed_to_float(twiddle_imag));
         
         // End simulation
         #(CLK_PERIOD*10);
         $display("Simulation complete");
         $finish;
     end
     
     // VCD dump for waveform viewing
     initial begin
         $dumpfile("tb_twiddle_factor_rom.vcd");
         $dumpvars(0, tb_twiddle_factor_rom);
     end
     
 endmodule