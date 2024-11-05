
/* tiny_tapeout_tb.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 *
 * Testbench for clock register, this tests the functionality of holding and
 * setting the time of the clock.
 */
`timescale 1ns / 1ns
`default_nettype none

`define assert(signal, value) \
  if (signal !== value) begin \
    $display("ASSERTION FAILED in %m:\n\t 0x%H (actual) != 0x%H (expected)", signal, value); \
    close(); \
  end

`define assert_cond(signal, cond, value) \
  if (!(signal cond value)) begin \
    $display("ASSERTION FAILED in %m:\n\t %d (actual), %d (expected)", signal, value); \
    close(); \
  end

module tiny_tapeout_tb ();
  // cocotb interface signals
  reg test_done = 0;
  reg clk_dummy = 0;

  // global testbench signals
  localparam CLK_PERIOD    = 100;
  localparam REFCLK_PERIOD = 200;
  localparam TIMEOUT_SHORT = 5000;
  localparam TIMEOUT_LONG  = 20000;

  reg clk = 0;
  reg rst_n = 0;
  reg ena = 1;

  reg run_timeout_counter;
  reg [15:0] timeout_counter = 0;

  // Named Module inputs/outputs
  reg refclk = 0;
  reg i_fast_set = 0;
  reg i_set_hours = 0;
  reg i_set_minutes = 0;

  wire serial_load;
  wire serial_dout;
  wire serial_clk;

  // setup actual Tiny Tapeout IO
  wire [7:0] ui_in;
  wire [7:0] uo_out;
  wire [7:0] uio_in = 8'h0;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  assign ui_in[0]   = refclk;
  assign ui_in[1]   = 1'b0;
  assign ui_in[2]   = i_fast_set;
  assign ui_in[3]   = i_set_hours;
  assign ui_in[4]   = i_set_minutes;
  assign ui_in[7:5] = 3'h0;

  assign serial_load = uio_out[0];
  assign serial_dout = uio_out[1];
  assign serial_clk = uio_out[3];

  // setup file dumping things
  localparam STARTUP_DELAY = 5;
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tiny_tapeout_tb);
    #STARTUP_DELAY;

    $display("Test Tiny Tapeout Wrapper");
    init();

    run_test();

    test_done = 1;
    // exit the simulator
    close();
  end

  // System Clock 
  localparam CLK_HALF_PERIOD = CLK_PERIOD / 2;
  always #(CLK_HALF_PERIOD) begin
    clk <= ~clk;
  end

  // Reference Clock
  localparam REFCLK_HALF_PERIOD = REFCLK_PERIOD / 2;
  always #(REFCLK_HALF_PERIOD) begin
    refclk <= ~refclk;
  end

  // Timeout Clock
  always @(posedge refclk) begin
    if (run_timeout_counter) timeout_counter <= timeout_counter + 1'd1;
    else timeout_counter <= 16'h0;
  end

// Setup the Tiny Tapeout Project
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  tt_um_digital_clock_example digital_clock (
`ifdef GL_TEST
    .VPWR(VPWR),
    .VGND(VGND),
`endif
    .ui_in  (ui_in),    // Dedicated inputs - connected to the input switches
    .uo_out (uo_out),   // Dedicated outputs - connected to the 7 segment display
    .uio_in (uio_in),   // IOs: Bidirectional Input path
    .uio_out(uio_out),  // IOs: Bidirectional Output path
    .uio_oe (uio_oe),   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    .ena    (ena),      // will go high when the design is enabled
    .clk    (clk),      // clock ~ 10MHz
    .rst_n  (rst_n)     // reset_n - low to reset
  );

  // Duplicate the input clocking modules to make using the testbench easier
  wire refclk_sync;
  wire clk_1hz_stb;
  wire clk_slow_set_stb;
  wire clk_fast_set_stb;
  wire clk_debounce_stb;

  refclk_sync refclk_sync_inst (
      .i_reset_n    (rst_n),
      .i_clk        (clk),
      .i_refclk     (refclk),
      .o_refclk_sync(refclk_sync)
  );

  clk_gen clk_gen_inst (
      .i_reset_n     (rst_n),
      .i_clk         (clk),
      .i_refclk      (refclk_sync),
      .o_1hz_stb     (clk_1hz_stb),
      .o_slow_set_stb(clk_slow_set_stb),
      .o_fast_set_stb(clk_fast_set_stb),
      .o_debounce_stb(clk_debounce_stb)
  );

  wire clk_set_stb = i_fast_set ? clk_fast_set_stb : clk_slow_set_stb;

  // Testbench modules for displaying the Tiny Tapeout Output
  wire [7:0] digit0;
  wire [7:0] digit1;
  wire [7:0] digit2;
  wire [7:0] digit3;
  wire [7:0] digit4;
  wire [7:0] digit5;
  wire [7:0] digit6;
  wire [7:0] digit7;

  test_max7219_moc display_out (
      .i_clk(clk),
      .i_serial_din(serial_dout),
      .i_serial_load(serial_load),
      .i_serial_clk(serial_clk),

      .o_digit0(digit0),
      .o_digit1(digit1),
      .o_digit2(digit2),
      .o_digit3(digit3),
      .o_digit4(digit4),
      .o_digit5(digit5),
      .o_digit6(digit6),
      .o_digit7(digit7)
  );

  wire [3:0] bcd0;
  wire [3:0] bcd1;
  wire [3:0] bcd2;
  wire [3:0] bcd3;
  wire [3:0] bcd4;
  wire [3:0] bcd5;
  wire [3:0] bcd6;
  wire [3:0] bcd7;

  test_7seg_to_bcd bcd0_conv (
      .i_led(digit0[6:0]),
      .o_bcd(bcd0)
  );
  test_7seg_to_bcd bcd1_conv (
      .i_led(digit1[6:0]),
      .o_bcd(bcd1)
  );
  test_7seg_to_bcd bcd2_conv (
      .i_led(digit2[6:0]),
      .o_bcd(bcd2)
  );
  test_7seg_to_bcd bcd3_conv (
      .i_led(digit3[6:0]),
      .o_bcd(bcd3)
  );
  test_7seg_to_bcd bcd4_conv (
      .i_led(digit4[6:0]),
      .o_bcd(bcd4)
  );
  test_7seg_to_bcd bcd5_conv (
      .i_led(digit5[6:0]),
      .o_bcd(bcd5)
  );
  test_7seg_to_bcd bcd6_conv (
      .i_led(digit6[6:0]),
      .o_bcd(bcd6)
  );
  test_7seg_to_bcd bcd7_conv (
      .i_led(digit7[6:0]),
      .o_bcd(bcd7)
  );

  wire [4:0] clktime_hours = bcd0 * 10 + bcd1;
  wire [5:0] clktime_minutes = bcd2 * 10 + bcd3;
  wire [5:0] clktime_seconds = bcd4 * 10 + bcd5;

  // Tasks for running simulations
  task reset_clock();
    begin : clock_reset
      integer update_count;
      integer timeout;

      if (i_fast_set)
        timeout = TIMEOUT_SHORT;
      else
        timeout = TIMEOUT_LONG;

      $display("Reset Seconds");
      clock_reset_seconds();

      $display("Reset Hours");
      i_fast_set   = 1'h1;
      i_set_hours  = 1'h1;
      update_count = 0;
      while (clktime_hours != 5'd0
          && timeout_counter < timeout
          && update_count < 30) begin

        @(posedge clk_set_stb);
        $display("Current Set Time: %02d:%02d.%02d",
                 clktime_hours,
                 clktime_minutes,
                 clktime_seconds);

        reset_timeout_counter();
        //repeat (6) @(posedge serial_load);
        repeat (150) @(posedge clk);  // this is because the gl simulation does weird things
        update_count = update_count + 1;
      end
      `assert(clktime_hours, 5'd0);

      $display("Reset Minutes");
      @(posedge clk);
      i_set_hours   = 1'h0;
      i_set_minutes = 1'h1;
      update_count  = 0;
      while (clktime_minutes != 6'd0
          && timeout_counter < timeout
          && update_count < 70) begin

        @(posedge clk_set_stb);
        $display("Current Set Time: %02d:%02d.%02d",
                 clktime_hours,
                 clktime_minutes,
                 clktime_seconds);

        reset_timeout_counter();
        //repeat (6) @(posedge serial_load);
        repeat (150) @(posedge clk);  // this is because the gl simulation does weird things
        update_count = update_count + 1;
      end
      `assert(clktime_minutes, 6'd0);

      @(posedge clk);
      clock_reset_seconds();

    end
  endtask

  task clock_set_hours(input [4:0] hours_settime);
    begin : set_hours
      integer update_count;
      integer timeout;

      if (i_fast_set)
        timeout = TIMEOUT_SHORT;
      else
        timeout = TIMEOUT_LONG;

      $display("Max Timeout: %d", timeout);

      i_set_hours = 1'h1;
      reset_timeout_counter();

      update_count = 0;
      while (clktime_hours < hours_settime
          && timeout_counter < timeout 
          && update_count < 30) begin

        @(posedge clk_set_stb);
        $display("Current Set Time: %02d:%02d.%02d",
                 clktime_hours,
                 clktime_minutes,
                 clktime_seconds);

        reset_timeout_counter();
        //repeat (6) @(posedge serial_load);
        repeat (150) @(posedge clk);  // this is because the gl simulation does weird things
        update_count = update_count + 1;
      end

      `assert_cond(update_count , <, 30);
      `assert_cond(timeout_counter, <, timeout);
      `assert(clktime_hours, hours_settime);
      @(posedge clk);
      run_timeout_counter = 1'h0;
      i_set_hours = 1'h0;
    end
  endtask

  task clock_set_minutes(input [5:0] minutes_settime);
    begin : set_minutes
      integer update_count;
      integer timeout;
      if (i_fast_set)
        timeout = TIMEOUT_SHORT;
      else
        timeout = TIMEOUT_LONG;

      i_set_minutes = 1'h1;
      reset_timeout_counter();

      update_count = 0;
      while (clktime_minutes != minutes_settime
          && timeout_counter <= timeout 
          && update_count < 70) begin

        @(posedge clk_set_stb);
        `assert_cond(timeout_counter, <, timeout);
        $display("Current Set Time: %02d:%02d.%02d",
                 clktime_hours,
                 clktime_minutes,
                 clktime_seconds);

        reset_timeout_counter();
        //repeat (6) @(posedge serial_load);
        repeat (150) @(posedge clk);  // this is because the gl simulation does weird things
        update_count = update_count + 1;
      end

      `assert_cond(update_count , <, 70);
      `assert_cond(timeout_counter, <, timeout);
      `assert(clktime_minutes, minutes_settime);
      @(posedge clk);
      run_timeout_counter = 1'h0;
      i_set_minutes = 1'h0;
    end
  endtask

  task clock_reset_seconds();
    begin
      i_set_hours   = 1'h1;
      i_set_minutes = 1'h1;
      repeat (2) @(posedge clk_set_stb);
      `assert(clktime_seconds, 6'h0);
      @(posedge clk);
      i_set_hours = 1'h0;
      i_set_minutes = 1'h0;
      run_timeout_counter = 1'h0;
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

  task run_test();
    begin
      // wait until the outputs are initilized
      reset_timeout_counter();
      @(posedge clk_set_stb);
      i_fast_set = 1'h1;
      reset_clock();

      // set the hours and minutes
      $display("Set Hours");
      clock_set_hours(10);
      $display("Time Set: %02d:%02d.%02d", clktime_hours, clktime_minutes, clktime_seconds);

      $display("Set Minutes");
      clock_set_minutes(59);
      $display("Time Set: %02d:%02d.%02d", clktime_hours, clktime_minutes, clktime_seconds);

      $display("Reset Seconds");
      clock_reset_seconds();
      $display("Time Set: %02d:%02d.%02d", clktime_hours, clktime_minutes, clktime_seconds);

      $display("Run Clock");
      repeat (61) @(posedge clk_1hz_stb);
      $display("Time Set: %02d:%02d.%02d", clktime_hours, clktime_minutes, clktime_seconds);

      i_fast_set = 1'h0;
      @(posedge clk_set_stb);

      // try rolling over the hours
      $display("Set Hours");
      clock_set_hours(23);
      $display("Set Minutes");
      clock_set_minutes(59);
      $display("Reset Seconds");
      clock_reset_seconds();
      $display("Time Set: %02d:%02d.%02d", clktime_hours, clktime_minutes, clktime_seconds);

      $display("Run Clock");
      repeat (61) @(posedge clk_1hz_stb);
      $display("Time Set: %02d:%02d.%02d", clktime_hours, clktime_minutes, clktime_seconds);
    end
  endtask

  task init();
    begin
      $display("Simulation Start");
      $display("Reset");

      repeat (2) @(posedge clk);
      rst_n = 1;
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
