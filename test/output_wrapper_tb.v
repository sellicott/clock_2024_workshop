/* output_wrapper_tb.v
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

module output_wrapper_tb ();

  // setup file dumping things
  localparam STARTUP_DELAY = 5;
  initial begin
    $dumpfile("output_wrapper_tb.fst");
    $dumpvars(0, output_wrapper_tb);
    #STARTUP_DELAY;

    $display("Test Display Output Wrapper Module");
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
  reg stb     = 0;

  always #(CLK_HALF_PERIOD) begin
    clk <= ~clk;
  end

  reg run_timeout_counter;
  reg [15:0] timeout_counter = 0;
  always @(posedge clk) begin
    if (run_timeout_counter)
      timeout_counter <= timeout_counter + 1'd1;
    else 
      timeout_counter <= 16'h0;
  end

  reg [4:0] clk_hours = 0;
  reg [5:0] clk_minutes = 0;
  reg [5:0] clk_seconds = 0;
  reg [5:0] clk_dp = 0;

  reg  write_config = 0;

  wire busy;
  wire ack;

  wire serial_dout;
  wire serial_load;
  wire serial_clk;

  output_wrapper display_inst (
    .i_reset_n (reset_n),
    .i_clk     (clk),
    .i_stb     (stb),
    .o_busy    (busy),
    .o_ack     (ack),

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

  wire [7:0] digit0;
  wire [7:0] digit1;
  wire [7:0] digit2;
  wire [7:0] digit3;
  wire [7:0] digit4;
  wire [7:0] digit5;
  wire [7:0] digit6;
  wire [7:0] digit7;

  test_max7219_moc display_out (
    .i_serial_din  (serial_dout),
    .i_serial_load (serial_load),
    .i_serial_clk  (serial_clk),

    .o_digit0 (digit0),
    .o_digit1 (digit1),
    .o_digit2 (digit2),
    .o_digit3 (digit3),
    .o_digit4 (digit4),
    .o_digit5 (digit5),
    .o_digit6 (digit6),
    .o_digit7 (digit7) 
  );

  wire [3:0] bcd0;
  wire [3:0] bcd1;
  wire [3:0] bcd2;
  wire [3:0] bcd3;
  wire [3:0] bcd4;
  wire [3:0] bcd5;
  wire [3:0] bcd6;
  wire [3:0] bcd7;
  
  test_7seg_to_bcd bcd0_conv ( .i_led(digit0[6:0]), .o_bcd(bcd0) );
  test_7seg_to_bcd bcd1_conv ( .i_led(digit1[6:0]), .o_bcd(bcd1) );
  test_7seg_to_bcd bcd2_conv ( .i_led(digit2[6:0]), .o_bcd(bcd2) );
  test_7seg_to_bcd bcd3_conv ( .i_led(digit3[6:0]), .o_bcd(bcd3) );
  test_7seg_to_bcd bcd4_conv ( .i_led(digit4[6:0]), .o_bcd(bcd4) );
  test_7seg_to_bcd bcd5_conv ( .i_led(digit5[6:0]), .o_bcd(bcd5) );
  test_7seg_to_bcd bcd6_conv ( .i_led(digit6[6:0]), .o_bcd(bcd6) );
  test_7seg_to_bcd bcd7_conv ( .i_led(digit7[6:0]), .o_bcd(bcd7) );


  localparam TIMEOUT = 6*32;
  task write_settings (
  );
    begin
      $display("Writing Display Settings");
      reset_timeout_counter();
      write_config = 1;
      stb = 1'd1;
      @(posedge clk);
      while(!busy)
        #1 stb = 1'd1;
      stb = 1'd0;

      while (busy && timeout_counter <= TIMEOUT) @(posedge clk);
      write_config = 0;
      `assert_cond(timeout_counter, <, TIMEOUT);
      `assert(ack, 1'b1)
      run_timeout_counter = 1'h0;
    end
  endtask

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
    write_config = 1'h0;
    stb = 1'h1;
    @(posedge clk);
    while (!busy)
      #1 stb = 1'h1;
    stb = 1'h0;

    while (busy && timeout_counter <= TIMEOUT) @(posedge clk);
    `assert_cond(timeout_counter, <, TIMEOUT);
    `assert(ack, 1'b1)
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
      write_settings();
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
