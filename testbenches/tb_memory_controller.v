/**
 * Testbench for the FFT Memory Controller
 * 
 * This testbench verifies the functionality of the memory controller
 * component of the FFT accelerator.
 */
 `timescale 1ns / 1ps

 module tb_memory_controller;
 
     // Parameters
     parameter DATA_WIDTH = 16;
     parameter FFT_POINTS = 64;
     parameter ADDR_WIDTH = 6;
     parameter CLK_PERIOD = 10;  // 10ns = 100MHz
     
     // Testbench signals
     reg                     clk;
     reg                     rst_n;
     reg                     start;
     reg  [2:0]              state;
     reg  [ADDR_WIDTH-1:0]   stage;
     reg  [ADDR_WIDTH:0]     butterfly_count;
     reg  [ADDR_WIDTH:0]     distance;
     reg                     data_valid;
     reg  [DATA_WIDTH-1:0]   data_in_real;
     reg  [DATA_WIDTH-1:0]   data_in_imag;
     reg  [ADDR_WIDTH-1:0]   addr_in;
     reg                     rd_en;
     reg  [ADDR_WIDTH-1:0]   addr_out;
     
     wire                    busy;
     wire                    done;
     wire                    memory_we;
     wire [ADDR_WIDTH-1:0]   memory_addr_in;
     wire [ADDR_WIDTH-1:0]   memory_addr_out;
     wire [DATA_WIDTH-1:0]   memory_data_in_real;
     wire [DATA_WIDTH-1:0]   memory_data_in_imag;
     wire [DATA_WIDTH-1:0]   data_out_real;
     wire [DATA_WIDTH-1:0]   data_out_imag;
     
     // Memory model
     reg [DATA_WIDTH-1:0]    memory_model_real [0:FFT_POINTS-1];
     reg [DATA_WIDTH-1:0]    memory_model_imag [0:FFT_POINTS-1];
     
     // File handle for output
     integer file_output;
     
     // Instantiate the FFT controller
     fft_controller #(
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
         .memory_data_out_real(memory_model_real[memory_addr_out]),
         .memory_data_out_imag(memory_model_imag[memory_addr_out]),
         
         .busy(busy),
         .done(done),
         .memory_we(memory_we),
         .memory_addr_in(memory_addr_in),
         .memory_addr_out(memory_addr_out),
         .memory_data_in_real(memory_data_in_real),
         .memory_data_in_imag(memory_data_in_imag),
         .data_out_real(data_out_real),
         .data_out_imag(data_out_imag)
     );
     
     // Clock generation
     always begin
         #(CLK_PERIOD/2) clk = ~clk;
     end
     
     // Memory model write
     always @(posedge clk) begin
         if (memory_we) begin
             memory_model_real[memory_addr_in] <= memory_data_in_real;
             memory_model_imag[memory_addr_in] <= memory_data_in_imag;
         end
     end
     
     // Test vectors
     reg signed [DATA_WIDTH-1:0] test_data_real [0:FFT_POINTS-1];
     reg signed [DATA_WIDTH-1:0] test_data_imag [0:FFT_POINTS-1];
     
     // Initialize memory and test data
     task initialize_memory;
         integer i;
         begin
             // Initialize memory model with zeros
             for (i = 0; i < FFT_POINTS; i = i + 1) begin
                 memory_model_real[i] = 0;
                 memory_model_imag[i] = 0;
             end
             
             // Initialize test data - Simple square wave
             for (i = 0; i < FFT_POINTS; i = i + 1) begin
                 if (i < FFT_POINTS/2)
                     test_data_real[i] = 16'h3000; // Positive value
                 else
                     test_data_real[i] = 16'hD000; // Negative value
                 
                 test_data_imag[i] = 16'h0000;     // All zeros for imaginary
             end
         end
     endtask
     
     // Task to load test data into memory
     task load_data;
         integer i;
         begin
             $display("Loading data into memory...");
             
             for (i = 0; i < FFT_POINTS; i = i + 1) begin
                 @(posedge clk);
                 data_valid = 1;
                 addr_in = i;
                 data_in_real = test_data_real[i];
                 data_in_imag = test_data_imag[i];
                 #1; // Small delay
             end
             
             @(posedge clk);
             data_valid = 0;
         end
     endtask
     
     // Task to verify memory access patterns during FFT computation
     task monitor_memory_access;
         integer cycle_count;
         begin
             cycle_count = 0;
             file_output = $fopen("memory_access_log.txt", "w");
             
             $fwrite(file_output, "Cycle,State,Stage,BflyCount,Dist,MemWE,AddrIn,AddrOut,DataInReal,DataInImag\n");
             
             while (busy) begin
                 @(posedge clk);
                 cycle_count = cycle_count + 1;
                 
                 $fwrite(file_output, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%h,%h\n", 
                         cycle_count, state, stage, butterfly_count, distance,
                         memory_we, memory_addr_in, memory_addr_out,
                         memory_data_in_real, memory_data_in_imag);
             end
             
             $fclose(file_output);
         end
     endtask
     
     // Task to check bit-reversal permutation
     task check_bit_reversal;
         integer i;
         reg [ADDR_WIDTH-1:0] bit_reversed;
         begin
             $display("Checking bit-reversal permutation...");
             file_output = $fopen("bit_reversal_check.txt", "w");
             
             for (i = 0; i < FFT_POINTS; i = i + 1) begin
                 // Manually calculate bit-reversed address
                 bit_reversed = 0;
                 for (int j = 0; j < ADDR_WIDTH; j = j + 1) begin
                     bit_reversed[ADDR_WIDTH-1-j] = i[j];
                 end
                 
                 $fwrite(file_output, "Address %0d -> Bit-reversed %0d\n", i, bit_reversed);
             end
             
             $fclose(file_output);
         end
     endtask
     
     // Test procedure
     initial begin
         // Initialize signals
         clk = 0;
         rst_n = 0;
         start = 0;
         state = 0;
         stage = 0;
         butterfly_count = 0;
         distance = 1;
         data_valid = 0;
         data_in_real = 0;
         data_in_imag = 0;
         addr_in = 0;
         rd_en = 0;
         addr_out = 0;
         
         // Initialize memory and test data
         initialize_memory();
         
         // Reset pulse
         #(CLK_PERIOD*2);
         rst_n = 1;
         #(CLK_PERIOD*2);
         
         // Test 1: Load data and verify memory write
         $display("Test 1: Load data and verify memory write");
         
         // Start the controller
         start = 1;
         #(CLK_PERIOD);
         start = 0;
         
         // Load test data
         load_data();
         
         // Verify data was loaded correctly
         for (int i = 0; i < FFT_POINTS; i = i + 1) begin
             if (memory_model_real[i] != test_data_real[i] || memory_model_imag[i] != test_data_imag[i]) begin
                 $display("Error: Data mismatch at address %0d", i);
                 $display("Expected: %h + %hi, Got: %h + %hi", 
                          test_data_real[i], test_data_imag[i],
                          memory_model_real[i], memory_model_imag[i]);
             end
         end
         
         // Test 2: Monitor memory access patterns during FFT computation
         $display("Test 2: Monitoring memory access patterns");
         
         // In practice, state machine state would be internal to the controller
         // We're using it here just for the testbench log
         state = 2; // COMPUTE state
         stage = 0;
         butterfly_count = 0;
         distance = 1;
         
         // Start monitoring in a parallel process
         fork
             monitor_memory_access();
         join_none
         
         // Wait for FFT completion
         wait(done);
         $display("FFT computation completed");
         
         // Test 3: Verify bit-reversal permutation
         $display("Test 3: Verify bit-reversal permutation");
         check_bit_reversal();
         
         // Test 4: Read output data
         $display("Test 4: Reading FFT results");
         
         for (int i = 0; i < FFT_POINTS; i = i + 1) begin
             @(posedge clk);
             rd_en = 1;
             addr_out = i;
             #1; // Small delay
             
             $display("FFT Output %0d: %h + %hi", i, data_out_real, data_out_imag);
         end
         
         @(posedge clk);
         rd_en = 0;
         
         // End simulation
         #(CLK_PERIOD*10);
         $display("Simulation complete");
         $finish;
     end
     
     // Monitor for checking signals
     initial begin
         $monitor("Time=%t, State: busy=%b, done=%b", $time, busy, done);
     end
     
     // VCD dump for waveform viewing
     initial begin
         $dumpfile("tb_memory_controller.vcd");
         $dumpvars(0, tb_memory_controller);
     end
     
 endmodule