
/* tb_template.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 *
 * Generic Verilog Testbench Template
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

module tb_template ();
  // cocotb interface signals
  reg test_done = 0;

  // global testbench signals
  localparam CLK_PERIOD    = 100;
  localparam TIMEOUT       = 5000;

  reg clk = 0;
  reg reset_n = 0;
  reg ena = 1;

  reg run_timeout_counter;
  reg [15:0] timeout_counter = 0;

  // setup top level testbench signals

  // TODO: Add signals here


  // setup file dumping things
  localparam STARTUP_DELAY = 5;
  initial begin
    $dumpfile("tb_template.fst");
    $dumpvars(0, tb_template);
    #STARTUP_DELAY;

    $display("Testbench Template");
    init();

    // TODO: Run all our tests here
    generic_task(TIMEOUT);

    test_done = 1;
    // exit the simulator
    close();
  end

  // System Clock 
  localparam CLK_HALF_PERIOD = CLK_PERIOD / 2;
  always #(CLK_HALF_PERIOD) begin
    clk <= ~clk;
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
