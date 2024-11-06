
/* clk_gen_tb.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 *
 * Testbench for the strobe signal generation module
 */
`timescale 1ns / 1ns
`default_nettype none

// Assert helpers for ending the simulation early in failure
`define assert(signal, value) \
  if (signal !== value) begin \
    $display("ASSERTION FAILED in %m:\nEquality"); \
    $display("\t%d (expected) != %d (actual)", value, signal); \
    close(); \
  end

`define assert_cond(signal, cond, value) \
  if (!(signal cond value)) begin \
    $display("ASSERTION FAILED in %m:\nCondition:"); \
    $display("\n\texpected: %d\n\tactual: %d", value, signal); \
    close(); \
  end

`define assert_timeout(max_count) \
  if (!(timeout_counter < max_count)) begin \
    $display("ASSERTION FAILED in %m\nTimeout:"); \
    $display("\tspecified max count: %d\n\tactual count: %d", max_count, timeout_counter); \
    close(); \
  end

module clk_gen_tb ();
  // cocotb interface signals
  reg test_done = 0;

  // global testbench signals
  localparam CLK_PERIOD    = 100;
  localparam TIMEOUT       = 5000;

  reg clk = 0;
  reg reset_n = 0;
  reg ena = 1;
  reg refclk = 0;

  reg run_timeout_counter;
  reg [15:0] timeout_counter = 0;

  wire clk_1hz_stb;
  wire clk_slow_set_stb;
  wire clk_fast_set_stb;
  wire debounce_stb;

  // setup top level testbench signals
  clk_gen clk_gen_inst (
    // global signals
    .i_reset_n(reset_n),
    .i_clk(clk),
    // Strobe from 32,768 Hz reference clock
    .i_refclk(refclk),
    // output strobe signals
    .o_1hz_stb(clk_1hz_stb),      // refclk / 2^15 -> 1Hz
    .o_slow_set_stb(clk_slow_set_stb), // refclk / 2^14 -> 2Hz
    .o_fast_set_stb(clk_fast_set_stb), // refclk / 2^12 -> 8Hz
    .o_debounce_stb(debounce_stb)  // refclk / 2^4  -> 4.096KHz
  );
  // TODO: Add signals here


  // setup file dumping things
  localparam STARTUP_DELAY = 5;
  initial begin: startup 
    integer i;
    $dumpfile("clk_gen_tb.fst");
    $dumpvars(0, clk_gen_tb);
    #STARTUP_DELAY;

    $display("Clock Strobe Generation Testbench");
    init();

    for (i = 0; i < 1000; i = i + 1) begin
      @(posedge clk);
      $display("%d", clk_1hz_stb);
    end 

    test_done = 1;
    // exit the simulator
    close();
  end

  // System Clock 
  localparam CLK_HALF_PERIOD = CLK_PERIOD / 2;
  always #(CLK_HALF_PERIOD) begin
    clk <= ~clk;
  end

  localparam REFCLK_HALF_PERIOD = 4*CLK_PERIOD;
  always #(REFCLK_HALF_PERIOD) begin
    refclk <= ~refclk;
  end

  // Timeout Clock
  always @(posedge clk) begin
    if (run_timeout_counter) timeout_counter <= timeout_counter + 1'd1;
    else timeout_counter <= 16'h0;
  end

  // setup power pins if doing post-synthesis simulations
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // This needs to be included in the ports list of any synthesized module so
  // that gate level simulations can be run
  //`ifdef GL_TEST
  //    .VPWR(VPWR),
  //    .VGND(VGND),
  //`endif

  // TODO: Add device to test here

  // Add any helper modules for displaying 
  // TODO: Add helper modules here

  // Tasks for running simulations
  // I usually put these at the end so that I can access all the signals in
  // the testbench
  task generic_task(
    input integer timeout
  );
    begin : my_generic_task
      $display("Timeout: %d", timeout);

      // reset our watchdog timer
      reset_timeout_counter();

      while ( /* some condition */ timeout_counter < timeout) begin 
        // TODO: Implement the generic task we want to accomplish
        @(posedge clk);
      end

      // make sure we didn't run out the watchdog timer
      `assert_timeout(timeout);
    end
  endtask

  task reset_timeout_counter();
    begin
      @(posedge clk);
      run_timeout_counter = 1'd0;
      @(posedge clk);
      run_timeout_counter = 1'd1;
    end
  endtask

  task init();
    begin
      $display("Simulation Start");
      $display("Reset");

      repeat (2) @(posedge clk);
      reset_n = 1;
      $display("Run");
    end
  endtask

  task close();
    begin
      $display("Closing");
      repeat (10) @(posedge clk);
      $finish;
    end
  endtask

endmodule
