/* max7219_tb.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 *
 * Testbench for max7219 driver
 */

`default_nettype none
`timescale 1ns / 1ns

`define assert(signal, value) \
  if (signal !== value) begin \
    $display("ASSERTION FAILED in %m:\n\t 0x%H (actual) != 0x%H (expected)", signal, value); \
    close(); \
  end

`define assert_cond(signal, cond, value) \
  if (!(signal cond value)) begin \
    $display("ASSERTION FAILED in %m:\n\t 0x%H (actual) != 0x%H (expected)", signal, value); \
    close(); \
  end

module max7219_tb ();

  // setup file dumping things
  localparam STARTUP_DELAY = 5;
  initial begin
    $dumpfile("max7219_tb.fst");
    $dumpvars(0, max7219_tb);
    #STARTUP_DELAY;

    $display("Test max7219 driver");
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

  reg run_timeout_counter;
  reg [15:0] timeout_counter = 0;
  always @(posedge clk) begin
    if (run_timeout_counter)
      timeout_counter <= timeout_counter + 1'd1;
    else 
      timeout_counter <= 16'h0;
  end

  reg stb;
  wire busy;
  wire ack;
  reg [3:0] addr;
  reg [7:0] data;

  wire serial_din = 0;
  wire serial_dout;
  wire serial_load;
  wire serial_clk;


  max7219 disp_driver (
    .i_reset_n (rst_n),
    .i_clk     (clk),
    .i_stb     (stb),
    .o_busy    (busy),
    .o_ack     (ack),

    .i_addr (addr),
    .i_data (data),

    .i_serial_din  (serial_din),
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
    .i_clk(clk),
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

  localparam TIMEOUT=64;
  task write_register (
    input [3:0] addr_t,
    input [7:0] data_t
  );
    begin
      $display("Write Data:\n\tAddress: 0x%H\n\tData: 0x%H", addr_t, data_t);
      reset_timeout_counter();
      while (busy && timeout_counter <= TIMEOUT) @(posedge clk);
      `assert_cond(timeout_counter, <, TIMEOUT);

      reset_timeout_counter();
      addr = addr_t;
      data = data_t;
      stb = 1'd1;
      @(posedge clk);
      while(!busy)
        #1 stb = 1'd1;
      stb = 1'd0;
      while (busy && timeout_counter <= TIMEOUT) @(posedge clk);
      `assert_cond(timeout_counter, <, TIMEOUT);
      run_timeout_counter = 1'h0;
      repeat(2) @(posedge clk);
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
      write_register(4'h9, 8'hFF); // all digits use bcd converters
      write_register(4'hA, 8'h07); // write intensity register ~50%
      write_register(4'hB, 8'h05); // write scan limit
      write_register(4'hC, 8'h01); // turn on display

      write_register(4'h1, 8'h00);
      `assert(bcd0, 4'h0);
      write_register(4'h2, 8'h01);
      `assert(bcd1, 4'h1);
      write_register(4'h3, 8'h02);
      `assert(bcd2, 4'h2);
      write_register(4'h4, 8'h03);
      `assert(bcd3, 4'h3);
      write_register(4'h5, 8'h04);
      `assert(bcd4, 4'h4);
      write_register(4'h6, 8'h05);
      `assert(bcd5, 4'h5);
      write_register(4'h1, 8'h06);
      `assert(bcd0, 4'h6);
      write_register(4'h2, 8'h07);
      `assert(bcd1, 4'h7);
      write_register(4'h3, 8'h08);
      `assert(bcd2, 4'h8);
      write_register(4'h4, 8'h09);
      `assert(bcd3, 4'h9);
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
