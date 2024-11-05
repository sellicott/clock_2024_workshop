/* display_controller_tb.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
`timescale 1ns / 1ns

`define assert(signal, value) \
  if (signal !== value) begin \
    $display("ASSERTION FAILED in %m:\n\t %b (actual) != %b (expected)", signal, value); \
    close(); \
  end

`define assert_cond(signal, cond, value) \
  if (!(signal cond value)) begin \
    $display("ASSERTION FAILED in %m:\n\t 0x%H (actual), 0x%H (expected)", signal, value); \
    close(); \
  end

module display_controller_tb ();

  // setup file dumping things
  localparam STARTUP_DELAY = 5;
  initial begin
    $dumpfile("display_controller_tb.fst");
    $dumpvars(0, display_controller_tb);
    #STARTUP_DELAY;

    $display("Test Display Controller Module");
    init();

    run_test();

    // exit the simulator
    close();
  end

  // setup global signals
  localparam CLK_PERIOD = 20;
  localparam CLK_HALF_PERIOD = CLK_PERIOD/2;

  reg clk     = 0;
  reg reset_n = 0;
  reg ena     = 1;

  always #(CLK_HALF_PERIOD) begin
    clk <= ~clk;
  end

  // model specific signals
  localparam REFCLK_PERIOD = 80;
  localparam REFCLK_HALF_PERIOD = REFCLK_PERIOD/2;
  reg refclk = 0;

  always #(REFCLK_HALF_PERIOD) begin
    refclk <= ~refclk;
  end

  // sync register
  wire refclk_sync;

  // clock strobe generator
  wire clk_1hz_stb;
  wire clk_slow_set_stb;
  wire clk_fast_set_stb;
 
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
    .o_fast_set_stb (clk_fast_set_stb)
  );

  wire clk_set_stb = clk_fast_set_stb;

  reg run_timeout_counter;
  reg [15:0] timeout_counter = 0;
  always @(posedge clk) begin
    if (run_timeout_counter)
      timeout_counter <= timeout_counter + 1'd1;
    else 
      timeout_counter <= 16'h0;
  end

  wire busy;
  wire ack;

  wire display_stb;
  wire display_busy;
  wire display_ack;

  wire write_config;

  display_controller display_controller_inst (
    .i_reset_n (reset_n),
    .i_clk     (clk),

    .i_1hz_stb     (clk_1hz_stb),
    .i_clk_set_stb (clk_set_stb),
    .i_clk_set     (1'h1),

    .o_display_stb (display_stb),
    .i_display_ack (display_ack),

    .o_write_config (write_config)
  );

  reg [4:0] clk_hours = 0;
  reg [5:0] clk_minutes = 0;
  reg [5:0] clk_seconds = 0;
  reg [5:0] clk_dp = 0;

  wire serial_dout;
  wire serial_load;
  wire serial_clk;

  output_wrapper display_inst (
    .i_reset_n (reset_n),
    .i_clk     (clk),
    .i_stb     (display_stb),
    .o_busy    (display_busy),
    .o_ack     (display_ack),

    .i_write_config (write_config),

    // input signals from the clock
    .i_hours   (clk_hours),
    .i_minutes (clk_minutes),
    .i_seconds (clk_seconds),
    .i_dp      (clk_dp),

    // SPI output
    .o_serial_dout (serial_dout),
    .o_serial_load (serial_load),
    .o_serial_clk  (serial_clk)
  );

  localparam TIMEOUT = 5000*REFCLK_PERIOD;

  task test_display(
    input [4:0] t_hours,
    input [5:0] t_minutes,
    input [5:0] t_seconds
  );
  begin
    $display("Testing: %02d:%02d.%02d", t_hours, t_minutes, t_seconds);

    reset_timeout_counter();
    @(posedge clk);
    clk_hours = t_hours;
    clk_minutes = t_minutes;
    clk_seconds = t_seconds;
    while (!clk_set_stb && timeout_counter <= TIMEOUT) @(posedge clk);
    $display("Timeout Count: 0x%h", timeout_counter);
    `assert_cond(timeout_counter, <, TIMEOUT);

    reset_timeout_counter();
    while (display_busy && timeout_counter <= TIMEOUT) @(posedge clk);
    `assert_cond(timeout_counter, <, TIMEOUT);
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
      reset_timeout_counter();
      while(!display_ack && timeout_counter <= TIMEOUT) @(posedge clk);
      
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
