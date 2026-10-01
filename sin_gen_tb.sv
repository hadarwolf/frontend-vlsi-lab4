`timescale 1ns / 1ps

// Optional: specific include if you aren't compiling files together in a project
// `include "sin_lut.sv" 
// `include "sin_gen.sv"

module tb_sin_gen;

    // 1. Signal Declaration
    logic clk;
    logic resetb;
    logic en;
    logic [7:0] period_sel;
    logic signed [8:0] sin_out;

    // 2. DUT Instantiation
    // Ensure "sin_gen.sv" has the bug fix (phase_cnt width [9:0]) before running!
    sin_gen dut (
        .clk(clk),
        .resetb(resetb),
        .en(en),
        .period_sel(period_sel),
        .sin_out(sin_out)
    );

    // 3. Clock Generation (100MHz -> 10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 4. Test Sequence
    initial begin
        // --- Initialize ---
        $display("Starting Simulation...");
        resetb = 0;
        en = 0;
        period_sel = 8'd0; // Fastest speed
        
        // --- Apply Reset ---
        #20;
        resetb = 1;
        $display("Reset Released.");
        #20;

        // --- Test 1: Start Sine Wave (Fastest) ---
        $display("[Time %0t] Enabling Generator (Fast)", $time);
        en = 1;
        
        // Wait for approx one full period (1024 clocks * 10ns = 10240ns)
        #11000;

        // --- Test 2: Change Speed On-the-fly ---
        $display("[Time %0t] Changing period_sel to 1 (Slower)", $time);
        period_sel = 8'd1; 

        // Wait for enough time to see the slow wave
        // Slow wave period = 1024 * 2 * 10ns = 20480ns
        #22000;

        // --- Test 3: Disable Logic ---
        $display("[Time %0t] Disabling Generator (en=0)", $time);
        en = 0;

        // Wait enough time to ensure it finished and went to zero
        #5000;

        // Check if output is actually zero (IDLE state)
        if (sin_out == 0) 
            $display("[Success] Output returned to 0 (IDLE).");
        else 
            $display("[Error] Output is %d, expected 0.", sin_out);

        $display("Simulation Finished.");
        $finish;
    end

endmodule