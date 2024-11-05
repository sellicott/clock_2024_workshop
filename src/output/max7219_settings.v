/*
 * max7219_settings.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 * updated: November 1, 2024
 *
 * Settings Driver for max7219 LED driver chip.
 * This driver writes max7219 data using the SPI driver.
 */
`default_nettype none

module max7219_settings (
  i_reset_n, // syncronous reset (active low)
  i_clk,     // fast system clock (~50MHz)
  i_stb,
  o_busy,
  o_ack,

  i_digit,
  i_segment,

  i_write_config,
  i_decode_mode,
  i_intensity,
  i_scan_limit,
  i_enable,
  i_display_test,

  i_next,  // connect to ack line of max7219 driver
  o_write, // connect to stb line of max7219 driver
  o_addr,
  o_data
);

  input  wire i_reset_n;
  input  wire i_clk;
  input  wire i_stb;
  output wire o_busy;
  output wire o_ack;

  localparam DECODE_MODE_ADDR  = 4'h9;
  localparam INTENSITY_ADDR    = 4'hA;
  localparam SCAN_LIMIT_ADDR   = 4'hB;
  localparam SHUTDOWN_ADDR     = 4'hC;
  localparam DISPLAY_TEST_ADDR = 4'hF;

  input wire [2:0] i_digit;
  input wire [7:0] i_segment;

  input wire       i_write_config;
  input wire [7:0] i_decode_mode;
  input wire [3:0] i_intensity;
  input wire [2:0] i_scan_limit;
  input wire       i_enable;
  input wire       i_display_test;

  reg       write_config;
  reg [7:0] decode_mode;
  reg [3:0] intensity;
  reg [2:0] scan_limit;
  reg       enable;
  reg       display_test;

  input  wire i_next;
  output wire o_write;
  output reg [3:0] o_addr;
  output reg [7:0] o_data;

  localparam IDLE      = 0;
  localparam LOAD      = 1;
  localparam TRANSFER  = 2;
  localparam REGISTERS = 5;
  localparam END_TRANSFER = TRANSFER + REGISTERS;

  wire start_transfer = (i_stb) && (!o_busy);
  
  reg [3:0] transfer_state;
  assign o_busy = (transfer_state > IDLE) && (transfer_state < END_TRANSFER);
  assign o_ack  = (transfer_state == END_TRANSFER);
  always @(posedge i_clk) begin
    // start the transfer sequence if we get a start signal and we aren't busy
    if (start_transfer) begin
      // only write once if we aren't writing the whole config
      transfer_state <= i_write_config ? LOAD : END_TRANSFER - 4'd1;
    end
    else if (transfer_state == LOAD) begin
      transfer_state <= transfer_state + 1'd1;
    end
    // immediately go to the transfer state after loading the data
    else if (transfer_state >= TRANSFER && i_next) begin 
      transfer_state <= transfer_state + 1'd1;
    end

    // only write once if we aren't writing the whole config
    //if (transfer_state >= TRANSFER && i_next && !write_config) begin
    //  transfer_state <= END_TRANSFER;
    //end

    if (transfer_state >= END_TRANSFER) begin 
      transfer_state <= IDLE;
    end

    if (!i_reset_n) begin 
      transfer_state <= IDLE;
    end
  end

  assign o_write = (transfer_state >= TRANSFER) && !o_ack;
  
  always @(posedge i_clk) begin 
    if (start_transfer) begin 
      write_config <= i_write_config;
      // store all of the config data for later use
      decode_mode  <= i_decode_mode;
      intensity    <= i_intensity;
      scan_limit   <= i_scan_limit;
      enable       <= i_enable;
      display_test <= i_display_test;
    end
    else if(transfer_state >= LOAD && write_config) begin
      case (transfer_state - LOAD)
        4'h0: begin
          o_addr <= DECODE_MODE_ADDR;
          o_data <= decode_mode;
        end
        4'h1: begin
          o_addr <= INTENSITY_ADDR;
          o_data <= {4'h0, intensity};
        end
        4'h2: begin
          o_addr <= SCAN_LIMIT_ADDR;
          o_data <= {5'h0, scan_limit};
        end
        4'h3: begin
          o_addr <= SHUTDOWN_ADDR;
          o_data <= {7'h0, enable};
        end
        4'h4: begin
          o_addr <= DISPLAY_TEST_ADDR;
          o_data <= {7'h0, display_test};
        end
      endcase
    end

    if (start_transfer && !i_write_config) begin
      o_addr <= i_digit + 1'd1;
      o_data <= i_segment;
    end

    if (!i_reset_n) begin 
      decode_mode  <= i_decode_mode;
      intensity    <= i_intensity;
      scan_limit   <= i_scan_limit;
      enable       <= i_enable;
      display_test <= i_display_test;
      o_addr <= 4'h0;
      o_data <= 8'h0;
    end
  end


endmodule
