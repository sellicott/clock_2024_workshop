
/* clock_register_tb.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 *
 * Testbench for clock register, this tests the functionality of holding and
 * setting the time of the clock.
 */

`default_nettype none
`timescale 1ns / 1ns

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

module clock_register_tb ();

  // global testbench signals
  localparam CLK_PERIOD    = 50;
  localparam REFCLK_PERIOD = 113;
  localparam TIMEOUT_SHORT = 2500;
  localparam TIMEOUT_LONG  = 15000;
  localparam TIMEOUT_1s    = 30000;

  reg run_timeout_counter;
  reg [15:0] timeout_counter = 0;
  // use reset_timeout_counter() to clear the counter
  // combine with `assert_timeout(max_count) to close simulation
  // when an action is taking too long

  // setup top level testbench signals
  reg ena = 1;
  reg reset_n = 0;
  reg clk = 0;
  reg refclk = 0;

  // wires and registers needed to test clock setting inputs
  reg i_fast_set    = 0;
  reg i_set_hours   = 0;
  reg i_set_minutes = 0;

  // Clock register Outputs
  wire [4:0] clk_hours;
  wire [5:0] clk_minutes;
  wire [5:0] clk_seconds;

  // clock strobe generator signals
  wire refclk_sync;
  wire clk_1hz_stb;
  wire clk_slow_set_stb;
  wire clk_fast_set_stb;
  wire clk_debounce_stb;

  // setup file dumping things
  localparam STARTUP_DELAY = 5;
  initial begin
    $dumpfile("clock_register_tb.fst");
    $dumpvars(0, clock_register_tb);
    #STARTUP_DELAY;

    $display("Test Clock Register");
    init();

    test_1hz_stb(TIMEOUT_1s);

    i_fast_set = 1'h1;

    $display("Minutes Rollover Test");
    // set the hours and minutes
    $display("Clock Set Hours");
    clock_set_hours(10, TIMEOUT_SHORT);
    $display("Time: %02d:%02d.%02d", clk_hours, clk_minutes, clk_seconds);

    $display("Clock Set Minutes");
    clock_set_minutes(59, TIMEOUT_SHORT);
    $display("Time: %02d:%02d.%02d", clk_hours, clk_minutes, clk_seconds);

    $display("Clock Reset Seconds");
    clock_reset_seconds(TIMEOUT_SHORT);
    $display("Time: %02d:%02d.%02d", clk_hours, clk_minutes, clk_seconds);

    $display("Wait 1 Minute");
    wait_1minute(TIMEOUT_1s);
    // we should overflow to 11:00.00
    $display("Time: %02d:%02d.%02d", clk_hours, clk_minutes, clk_seconds);
    `assert(clk_hours, 5'd11);
    `assert(clk_minutes, 6'd0);
    `assert(clk_seconds, 6'd0);

    // try rolling over the hours
    $display("Hours Rollover Test");
    $display("Clock Set Hours");
    clock_set_hours(23, TIMEOUT_LONG);
    $display("Time: %02d:%02d.%02d", clk_hours, clk_minutes, clk_seconds);

    $display("Clock Set Minutes");
    clock_set_minutes(59, TIMEOUT_LONG);
    $display("Time: %02d:%02d.%02d", clk_hours, clk_minutes, clk_seconds);

    $display("Clock Reset Seconds");
    clock_reset_seconds(TIMEOUT_LONG);
    $display("Time: %02d:%02d.%02d", clk_hours, clk_minutes, clk_seconds);

    $display("Wait 1 Minute");
    wait_1minute(TIMEOUT_1s);
    // we shoud overflow to 00:00.00
    $display("Time: %02d:%02d.%02d", clk_hours, clk_minutes, clk_seconds);
    `assert(clk_hours, 5'd0);
    `assert(clk_minutes, 6'd0);
    `assert(clk_seconds, 6'd0);

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

  // Helper modules for generating input signals

  // blocks used to generate signals for the button debouncer
 
  refclk_sync refclk_sync_inst (
    .i_reset_n     (reset_n),
    .i_clk         (clk),
    .i_refclk      (refclk),
    .o_refclk_sync (refclk_sync)
  );

  clk_gen clk_gen_inst (
    .i_reset_n      (reset_n),
    .i_clk          (clk),
    .i_refclk       (refclk_sync),
    .o_1hz_stb      (clk_1hz_stb),
    .o_slow_set_stb (clk_slow_set_stb),
    .o_fast_set_stb (clk_fast_set_stb),
    .o_debounce_stb (clk_debounce_stb)
  );

  wire clk_fast_set;
  wire clk_set_hours;
  wire clk_set_minutes;

  button_debounce input_debounce (
    .i_reset_n (reset_n),
    .i_clk     (clk),
    
    .i_debounce_stb (clk_debounce_stb),
    
    .i_fast_set    (i_fast_set),
    .i_set_hours   (i_set_hours),
    .i_set_minutes (i_set_minutes),
    
    .o_fast_set_db    (clk_fast_set),
    .o_set_hours_db   (clk_set_hours),
    .o_set_minutes_db (clk_set_minutes)
  );

  wire clk_set_stb = clk_fast_set ? clk_fast_set_stb : clk_slow_set_stb;

  clock_register clock_reg_inst (
    // global signals
    .i_reset_n (reset_n),
    .i_clk     (clk),

    // timing strobes
    .i_1hz_stb (clk_1hz_stb),
    .i_set_stb (clk_set_stb),

    // clock setting inputs
    .i_set_hours   (clk_set_hours),
    .i_set_minutes (clk_set_minutes),

    // time outputs
    .o_hours   (clk_hours),
    .o_minutes (clk_minutes),
    .o_seconds (clk_seconds)
  );

  task clock_set_hours (
    input [4:0] hours_settime,
    input integer timeout
  );
    begin: my_hours_set
      integer update_count;

      // start setting the clock
      @(posedge clk);
      i_set_hours = 1'h1;

      // reset our watchdog timer
      reset_timeout_counter();

      // try and set the clock by waiting until the clock is set
      update_count = 0;
      while (clk_hours != hours_settime       // desired end condition
          && update_count < 30                // maximum loop iterations
          && timeout_counter < timeout) begin // timeout condition

        @(posedge clk_set_stb);
        // display the clock state on rising edges of the stb signal
        $display("Current Set Time: %02d:%02d.%02d",
                clk_hours,
                clk_minutes,
                clk_seconds);

        // reset watchdog timer on each update
        reset_timeout_counter();

        // we should only take a maximum of 24 counts to reach any other
        // value in the clock
        update_count = update_count + 1;
      end

      // make sure we didn't run out the watchdog timer
      `assert_timeout(timeout);

      // make sure we didn't perform too many loops
      `assert_cond(update_count, <, 30);

      // make sure we actually set the correct time
      `assert(clk_hours, hours_settime);

      @(posedge clk);
      i_set_hours = 1'h0;
      run_timeout_counter = 1'h0;
    end
  endtask

  task clock_set_minutes (
    input [5:0] minutes_settime,
    input integer timeout
  );
    begin: my_minutes_set
      integer update_count;

      // start setting the clock
      @(posedge clk);
      i_set_minutes = 1'h1;

      // reset our watchdog timer
      reset_timeout_counter();

      // try and set the clock by waiting until the clock is set
      update_count = 0;
      while (clk_minutes != minutes_settime   // desired end condition
          && update_count < 70                // maximum loop iterations
          && timeout_counter < timeout) begin // timeout condition

        @(posedge clk_set_stb);

        $display("Current Set Time: %02d:%02d.%02d",
                clk_hours,
                clk_minutes,
                clk_seconds);

        // reset watchdog timer on each loop iteration
        reset_timeout_counter();

        // we should only take a maximum of 60 counts to reach any other
        // value in the clock
        update_count = update_count + 1;
      end

      // make sure we didn't run out the watchdog timer
      `assert_timeout(timeout);

      // make sure we didn't perform too many loops
      `assert_cond(update_count, <, 70);

      // make sure we actually set the correct time
      `assert(clk_minutes, minutes_settime);

      @(posedge clk);
      i_set_minutes = 1'h0;
      run_timeout_counter = 1'h0;
    end
  endtask

  task clock_reset_seconds (
    input integer timeout
  );
    begin: my_reset_seconds
      i_set_hours   = 1'h1;
      i_set_minutes = 1'h1;
      // reset our watchdog timer
      reset_timeout_counter();
      while (clk_seconds != 5'd0              // desired end condition
          && timeout_counter < timeout) begin // timeout condition

        @(posedge clk);
      end

      // make sure we didn't run out the watchdog timer
      `assert_timeout(timeout);

      // make sure the time is set correctly
      `assert(clk_seconds, 5'd0);

      @(posedge clk);
      i_set_hours   = 1'h0;
      i_set_minutes = 1'h0;
    end
  endtask

  task wait_1minute(
    input integer timeout
  );
    begin
      // delay for 1s
      reset_timeout_counter();
      while (clk_seconds == 6'd0              // desired end condition
          && timeout_counter < timeout) begin // timeout condition

          @(posedge clk_1hz_stb);
          reset_timeout_counter();
      end
      // make sure we didn't timeout
      `assert_timeout(timeout)
      $display("Time: %02d:%02d.%02d",
                clk_hours,
                clk_minutes,
                clk_seconds);

      // delay for 59 seconds
      reset_timeout_counter();
      while (clk_seconds != 6'd0              // desired end condition
          && timeout_counter < timeout) begin // timeout condition

          @(posedge clk_1hz_stb);
          $display("Time: %02d:%02d.%02d",
                  clk_hours,
                  clk_minutes,
                  clk_seconds);

          reset_timeout_counter();
      end
      `assert_timeout(timeout)
    end
  endtask

  task test_1hz_stb(
    input integer timeout
  );
    begin
      reset_timeout_counter();
      while (!clk_1hz_stb && timeout_counter < timeout) begin
          @(posedge clk);
      end
      // make sure we didn't timeout
      `assert_timeout(timeout)
      `assert(clk_1hz_stb, 1'b1);
    end
  endtask

  task reset_timeout_counter();
    begin
      @(posedge clk);
      run_timeout_counter = 1'd0;
      @(posedge clk);
      @(posedge clk);
      run_timeout_counter = 1'd1;
    end
  endtask

  task init();
    begin
      $display("Simulation Start");
      $display("Reset");

      repeat(2) @(posedge clk);
      reset_n = 1;
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
