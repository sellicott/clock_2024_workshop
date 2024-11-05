/* binary_to_bcd_tb.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 *
 * Testbench for clock_to_7seg.v file
 */

`default_nettype none
`timescale 1ns / 1ns

`define assert(signal, value) \
  if (signal !== value) begin \
    $display("ASSERTION FAILED in %m:\n\t %b (actual) != %b (expected)", signal, value); \
    close(); \
  end

module clock_to_7seg_tb();

  // setup file dumping things
  localparam STARTUP_DELAY = 5;
  initial begin
    $dumpfile("clock_to_7seg_tb.fst");
    $dumpvars(0, clock_to_7seg_tb);
    #STARTUP_DELAY;

    $display("Test Conversion from Clock -> 7-segment");
    init();

    run_test();

    // exit the simulator
    close();
  end

  // setup global signals
  localparam CLK_PERIOD = 20;
  localparam CLK_HALF_PERIOD = CLK_PERIOD/2;

  reg clk   = 0;
  reg rst_n = 0;
  reg ena   = 1;

  always #(CLK_HALF_PERIOD) begin
    clk <= ~clk;
  end

  reg [4:0] clk_hours = 0;
  reg [5:0] clk_minutes = 0;
  reg [5:0] clk_seconds = 0;
  reg [5:0] clk_dp = 0;
  reg [3:0] seg_select = 0;

  wire [7:0] clk_disp;
  wire [3:0] disp_bcd;


  clock_to_7seg clock_to_7seg_conv_inst (
    // input signals from the clock
    .i_hours   (clk_hours),
    .i_minutes (clk_minutes),
    .i_seconds (clk_seconds),
    .i_dp      (clk_dp),

    // select what part of the clock output to convert
    // 0 -> hours MSD, 5 -> seconds lSD
    .i_seg_select (seg_select),

    // 7-segment display output o_7seg[7] -> decimal point
    .o_7seg (clk_disp)
  );

  test_7seg_to_bcd test_7seg (
    .i_led (clk_disp[6:0]),
    .o_bcd (disp_bcd)
  );

  task test_display(
    input [4:0] t_hours,
    input [5:0] t_minutes,
    input [5:0] t_seconds
  );
  begin
    $display("Testing: %02d:%02d.%02d", t_hours, t_minutes, t_seconds);

    @(posedge clk);
    clk_hours = t_hours;
    clk_minutes = t_minutes;
    clk_seconds = t_seconds;
    seg_select = 4'h0;
    @(negedge clk);
    `assert(disp_bcd, t_hours / 10);

    @(posedge clk)
    seg_select = 4'h1;
    @(negedge clk);
    `assert(disp_bcd, t_hours % 10);

    @(posedge clk)
    seg_select = 4'h2;
    @(negedge clk);
    `assert(disp_bcd, t_minutes / 10);

    @(posedge clk)
    seg_select = 4'h3;
    @(negedge clk);
    `assert(disp_bcd, t_minutes % 10);

    @(posedge clk)
    seg_select = 4'h4;
    @(negedge clk);
    `assert(disp_bcd, t_seconds / 10);

    @(posedge clk)
    seg_select = 4'h5;
    @(negedge clk);
    `assert(disp_bcd, t_seconds % 10);
  end
  endtask
  

  task run_test();
    begin
      test_display(5'd0, 6'd0, 6'd0);
      test_display(5'd12, 6'd30, 6'd59);
      test_display(5'd23, 6'd15, 6'd30);
    end
  endtask

  task init();
    begin
      $display("Simulation Start");
      $display("Reset");

      repeat(2) @(posedge clk);
      rst_n = 1;
      $display("Run");
    end
  endtask

  task close();
    begin
      $display("Closing");
      repeat(10) @(posedge clk);
      $finish;
    end
  endtask

endmodule
