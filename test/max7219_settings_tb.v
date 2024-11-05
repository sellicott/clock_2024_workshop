/* max7219_sttings_tb.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 *
 * Testbench for max7219 settings driver
 */

`default_nettype none `timescale 1ns / 1ns

`define assert(signal, value) \
  if (signal !== value) begin \
    $display("ASSERTION FAILED in %m:\n\t 0x%H (actual) != 0x%H (expected)", signal, value); \
    close(); \
  end

`define assert_cond(signal, cond, value) \
  if (!(signal cond value)) begin \
    $display("ASSERTION FAILED in %m:\n\t 0x%H (actual), 0x%H (expected)", signal, value); \
    close(); \
  end

module max7219_settings_tb ();

  // setup file dumping things
  localparam STARTUP_DELAY = 5;
  initial begin
    $dumpfile("max7219_settings_tb.fst");
    $dumpvars(0, max7219_settings_tb);
    #STARTUP_DELAY;

    $display("Test max7219_settings driver");
    init();

    run_test();

    // exit the simulator
    close();
  end

  // setup global signals
  localparam CLK_PERIOD = 20;
  localparam CLK_HALF_PERIOD = CLK_PERIOD / 2;

  reg clk = 0;
  reg rst_n = 0;
  reg ena = 1;

  always #(CLK_HALF_PERIOD) begin
    clk <= ~clk;
  end

  reg run_timeout_counter;
  reg [15:0] timeout_counter = 0;
  always @(posedge clk) begin
    if (run_timeout_counter) timeout_counter <= timeout_counter + 1'd1;
    else timeout_counter <= 16'h0;
  end

  reg        stb = 0;
  wire       busy;
  wire       ack;
  reg  [2:0] digit = 0;
  reg  [3:0] bcd = 4'hf;

  reg        write_config = 0;
  reg  [7:0] decode_mode = 8'hf;
  reg  [3:0] intensity = 4'h7;
  reg  [2:0] scan_limit = 3'h5;
  reg        enable = 1;
  reg        display_test = 0;

  wire       max7219_ack;
  wire       max7219_stb;
  wire [3:0] addr;
  wire [7:0] data;

  max7219_settings display_settings (
      .i_reset_n(rst_n),  // syncronous reset (active low)
      .i_clk    (clk),    // fast system clock (~50MHz)
      .i_stb    (stb),
      .o_busy   (busy),
      .o_ack    (ack),

      .i_digit  (digit),
      .i_segment({4'h0, bcd}),

      .i_write_config(write_config),
      .i_decode_mode (decode_mode),
      .i_intensity   (intensity),
      .i_scan_limit  (scan_limit),
      .i_enable      (enable),
      .i_display_test(display_test),

      .i_next (max7219_ack),  // connect to ack line of max7219 driver
      .o_write(max7219_stb),  // connect to stb line of max7219 driver
      .o_addr (addr),
      .o_data (data)
  );

  wire max7219_busy;
  wire serial_din = 0;
  wire serial_dout;
  wire serial_load;
  wire serial_clk;

  max7219 disp_driver (
      .i_reset_n(rst_n),
      .i_clk    (clk),
      .i_stb    (max7219_stb),
      .o_busy   (max7219_busy),
      .o_ack    (max7219_ack),

      .i_addr(addr),
      .i_data(data),

      .i_serial_din (serial_din),
      .o_serial_dout(serial_dout),
      .o_serial_load(serial_load),
      .o_serial_clk (serial_clk)
  );


  localparam SETTINGS_WRITE_TIMEOUT = 5 * 32;
  task write_settings();
    begin
      $display("Writing MAX7219 Settings");
      reset_timeout_counter();
      while (busy && timeout_counter <= SETTINGS_WRITE_TIMEOUT) @(posedge clk);
      `assert_cond(timeout_counter, <, SETTINGS_WRITE_TIMEOUT);

      reset_timeout_counter();
      write_config = 1;
      stb = 1'd1;
      @(posedge clk);
      while (!busy) #1 stb = 1'd1;
      stb = 1'd0;

      while (busy && timeout_counter <= SETTINGS_WRITE_TIMEOUT) @(posedge clk);
      `assert_cond(timeout_counter, <, SETTINGS_WRITE_TIMEOUT);
      `assert(ack, 1'b1)
      run_timeout_counter = 1'h0;
    end
  endtask

  localparam TIMEOUT = 64;
  task write_digit(input [2:0] digit_t, input [3:0] bcd_digit_t);
    begin
      $display("Write Data:\n\tDigit: %d\n\tData: %d", digit_t, bcd_digit_t);
      reset_timeout_counter();
      while (busy && timeout_counter <= TIMEOUT) @(posedge clk);
      `assert_cond(timeout_counter, <, TIMEOUT);

      reset_timeout_counter();
      digit = digit_t;
      bcd = bcd_digit_t;
      write_config = 0;
      stb = 1'd1;
      @(posedge clk);
      while (!busy) #1 stb = 1'd1;
      stb = 1'd0;
      while (busy && timeout_counter <= TIMEOUT) begin
        `assert(addr, {4'h0, digit_t + 1'd1});
        `assert(data, {4'h0, bcd_digit_t});
        @(posedge clk);
      end
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
      write_digit(3'h0, 4'hF);  // all digits use bcd converters
      write_digit(3'h1, 4'h7);  // write intensity register ~50%
      write_digit(3'h2, 4'h5);  // write scan limit
      write_digit(3'h3, 4'h1);  // turn on display
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
