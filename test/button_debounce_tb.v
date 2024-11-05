
/* button_debounce_tb.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 *
 * Button debouncing module. Syncronizes input signals then takes NUM_SAMPLES
 * based on the i_debounce_stb input. If all samples are 1, output 1,
 * otherwise 0.
 * The debounce_stb signal is expected to be about 4KHz, therefore if 
 * NUM_SAMPLES is 5, the button must be bounce free for ~1.25us
 * in order to output 1.
 */

`default_nettype none
`timescale 1ns / 1ns

module button_debounce_tb ();

  // setup file dumping things
  localparam STARTUP_DELAY = 5;
  initial begin
    $dumpfile("button_debounce_tb.fst");
    $dumpvars(0, button_debounce_tb);
    #STARTUP_DELAY;

    $display("Test Button Debouncing");
    init();

    run_test();

    // exit the simulator
    close();
  end

  // setup global signals
  localparam CLK_PERIOD = 50;
  localparam CLK_HALF_PERIOD = CLK_PERIOD/2;

  reg clk   = 0;
  reg rst_n = 0;
  reg ena   = 1;

  always #(CLK_HALF_PERIOD) begin
    clk <= ~clk;
  end


  // model specific signals
  localparam REFCLK_PERIOD = 113;
  localparam REFCLK_HALF_PERIOD = REFCLK_PERIOD/2;
  reg refclk = 0;

  // sync register
  wire refclk_sync;

  // blocks used to generate signals for the button debouncer
  // clock strobe generator
  wire clk_1hz_stb;
  wire clk_slow_set_stb;
  wire clk_fast_set_stb;
  wire clk_debounce_stb;
 
  refclk_sync refclk_sync_inst (
    .i_reset_n     (rst_n),
    .i_clk         (clk),
    .i_refclk      (refclk),
    .o_refclk_sync (refclk_sync)
  );

  clk_gen clk_gen_inst (
    .i_reset_n      (rst_n),
    .i_clk          (clk),
    .i_refclk       (refclk_sync),
    .o_1hz_stb      (clk_1hz_stb),
    .o_slow_set_stb (clk_slow_set_stb),
    .o_fast_set_stb (clk_fast_set_stb),
    .o_debounce_stb (clk_debounce_stb)
  );

  reg i_fast_set    = 0;
  reg i_set_hours   = 0;
  reg i_set_minutes = 0;

  wire clk_fast_set;
  wire clk_set_hours;
  wire clk_set_minutes;


  button_debounce input_debounce (
    .i_reset_n (rst_n),
    .i_clk     (clk),
    
    .i_debounce_stb (clk_debounce_stb),
    
    .i_fast_set    (i_fast_set),
    .i_set_hours   (i_set_hours),
    .i_set_minutes (i_set_minutes),
    
    .o_fast_set_db    (clk_fast_set),
    .o_set_hours_db   (clk_set_hours),
    .o_set_minutes_db (clk_set_minutes)
  );

  always #(REFCLK_HALF_PERIOD) begin
    refclk <= ~refclk;
  end

  // generate random bounces on a given register
  localparam MAX_BOUNCE_TIME = 100*REFCLK_PERIOD;
  task bounce_fast_set(
   input  final_value
  );
  begin: bounce_task
    integer i;
    integer bounce_time;
    integer next_bounce;
    integer time_remaining;

    $display("Bouncing!");

    bounce_time = 0;
    while (bounce_time < 2*CLK_PERIOD) begin
      bounce_time = $urandom % MAX_BOUNCE_TIME;
    end
    time_remaining = bounce_time;
    $display("Bounce Time (ns): %d", bounce_time);

  
    while (time_remaining > 5) begin
      next_bounce = ($urandom % time_remaining/2) + 1;
      i_fast_set = ~i_fast_set;
      time_remaining = time_remaining - next_bounce;
      $display("[%0t] Time Remaining: %d, next delay: %d", $time, time_remaining, next_bounce);
      #next_bounce;
    end
    #1;
    i_fast_set = final_value;
  end
  endtask

  task bounce_set_hours(
   input  final_value
  );
  begin: bounce_set_hours 
    integer i;
    integer bounce_time;
    integer next_bounce;
    integer time_remaining;

    $display("Bouncing Hours!");

    bounce_time = 0;
    while (bounce_time < 2*CLK_PERIOD) begin
      bounce_time = $urandom % MAX_BOUNCE_TIME;
    end
    time_remaining = bounce_time;
    $display("Bounce Time (ns): %d", bounce_time);

  
    while (time_remaining > 5) begin
      next_bounce = ($urandom % time_remaining/2) + 1;
      i_set_hours = ~i_set_hours;
      time_remaining = time_remaining - next_bounce;
      $display("[%0t] Time Remaining: %d, next delay: %d", $time, time_remaining, next_bounce);
      #next_bounce;
    end
    #1;
    i_set_hours = final_value;
  end
  endtask

  task bounce_set_minutes (
   input  final_value
  );
  begin: bounce_set_minutes
    integer i;
    integer bounce_time;
    integer next_bounce;
    integer time_remaining;

    $display("Bouncing Minutes!");

    bounce_time = 0;
    while (bounce_time < 2*CLK_PERIOD) begin
      bounce_time = $urandom % MAX_BOUNCE_TIME;
    end
    time_remaining = bounce_time;
    $display("Bounce Time (ns): %d", bounce_time);

  
    while (time_remaining > 5) begin
      next_bounce = ($urandom % time_remaining/2) + 1;
      i_set_minutes= ~i_set_minutes;
      time_remaining = time_remaining - next_bounce;
      $display("[%0t] Time Remaining: %d, next delay: %d", $time, time_remaining, next_bounce);
      #next_bounce;
    end
    #1;
    i_set_minutes = final_value;
  end
  endtask

  task run_test();
    begin
      repeat(6) @(posedge clk_debounce_stb);
      bounce_fast_set(1);
      repeat(6) @(posedge clk_debounce_stb);

      bounce_set_hours(1);
      repeat(6) @(posedge clk_debounce_stb);

      bounce_fast_set(0);
      bounce_set_minutes(1);
      repeat(6) @(posedge clk_debounce_stb);

      bounce_set_hours(0);
      repeat(6) @(posedge clk_debounce_stb);

      bounce_set_minutes(0);
      repeat(6) @(posedge clk_debounce_stb);
      repeat(6) @(posedge clk_debounce_stb);
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
