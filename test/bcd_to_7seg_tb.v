/* bcd_to_7seg_tb.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 *
 * Test conversion from bcd numbers to 7-segment outputs
 */

`timescale 1ns / 1ns
`default_nettype none

module bcd_to_7seg_tb ();

  // setup file dumping things
  localparam STARTUP_DELAY = 5;
  initial begin
    $dumpfile("bcd_to_7seg_tb.fst");
    $dumpvars(0, bcd_to_7seg_tb);
    #STARTUP_DELAY;

    $display("Test Clock Strobe Generation");
    init();

    run_test();

    // exit the simulator
    close();
  end

  // setup global signals
  localparam CLK_PERIOD = 80;
  localparam CLK_HALF_PERIOD = CLK_PERIOD/2;

  reg clk   = 0;
  reg rst_n = 0;
  reg ena   = 1;

  always #(CLK_HALF_PERIOD) begin
    clk <= ~clk;
  end

  reg  [3:0] bcd = 15;
  wire [6:0] led;

  bcd_to_7seg bcd_disp_inst (
    .i_bcd(bcd),
    .o_led(led)
  );

  task display_bcd();
    begin
      case(led)
        7'b1111110: $display("0");  // 0
        7'b0110000: $display("1");  // 1
        7'b1101101: $display("2");  // 2
        7'b1111001: $display("3");  // 3
        7'b0110011: $display("4");  // 4
        7'b1011011: $display("5");  // 5
        7'b1011111: $display("6");  // 6
        7'b1110000: $display("7");  // 7
        7'b1111111: $display("8");  // 8
        7'b1111011: $display("9");  // 9
        default : $display("Invalid");  // default is to output nothing
      endcase
    end
  endtask

  task run_test();
    begin: run_test_blk
      integer i;
      for ( i = 0;  i < 16; i = i + 1) begin
        @(posedge clk);
        bcd = i;
        display_bcd();
      end
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

  `define assert(signal, value) \
    if (signal !== value) begin \
      $display("ASSERTION FAILED in %m: %b (actual) != %b (expected)", signal, value); \
      $finish; \
    end

endmodule
