/*
 * test_max7912_moc.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 * updated: November 1, 2024
 *
 * Driver for max7219 LED driver chip.
 * This driver writes data as a SPI output.
 */
`default_nettype none

module test_max7219_moc (
  i_clk,
  i_serial_din,
  i_serial_load,
  i_serial_clk,

  o_digit0,
  o_digit1,
  o_digit2,
  o_digit3,
  o_digit4,
  o_digit5,
  o_digit6,
  o_digit7
);

  input wire i_clk;
  input wire i_serial_din;
  input wire i_serial_load;
  input wire i_serial_clk;

  output wire [7:0] o_digit0;
  output wire [7:0] o_digit1;
  output wire [7:0] o_digit2;
  output wire [7:0] o_digit3;
  output wire [7:0] o_digit4;
  output wire [7:0] o_digit5;
  output wire [7:0] o_digit6;
  output wire [7:0] o_digit7;

  localparam DUMMY_ADDR        = 4'h0;
  localparam DECODE_MODE_ADDR  = 4'h9;
  localparam INTENSITY_ADDR    = 4'hA;
  localparam SCAN_LIMIT_ADDR   = 4'hB;
  localparam SHUTDOWN_ADDR     = 4'hC;
  localparam DISPLAY_TEST_ADDR = 4'hF;


  reg [7:0] digit [7:0];
  reg [7:0] digit_out [7:0];
  
  reg [7:0] decode_mode  = 0;
  reg [3:0] intensity    = 0;
  reg [2:0] scan_limit   = 0;
  reg       enable       = 0;
  reg       display_test = 0;
  reg [15:0] data_reg    = 0; 
  wire [3:0] addr = data_reg[11:8];
  wire [7:0] data = data_reg[7:0];

  initial begin: startup
    integer i;
    for (i = 0; i < 8; i = i + 1) begin
      digit[i] = 8'h0;
    end
  end

  always @(posedge i_serial_clk) begin
    if (!i_serial_load) begin
      data_reg <= {data_reg[14:0], i_serial_din};
    end
  end

  always @(posedge i_clk) begin 
    if (i_serial_load) begin 
      case (addr)
        DUMMY_ADDR: ;
        4'h1: digit[0] <= data;
        4'h2: digit[1] <= data;
        4'h3: digit[2] <= data;
        4'h4: digit[3] <= data;
        4'h5: digit[4] <= data;
        4'h6: digit[5] <= data;
        4'h7: digit[6] <= data;
        4'h8: digit[7] <= data;
        //DECODE_MODE_ADDR:  decode_mode  <= data;
        DECODE_MODE_ADDR:  decode_mode  <= 8'hff;
        INTENSITY_ADDR:    intensity    <= data[3:0];
        SCAN_LIMIT_ADDR:   scan_limit   <= data[2:0];
        //SCAN_LIMIT_ADDR:   scan_limit   <= 3'd7;
        SHUTDOWN_ADDR:     enable       <= data[0];
        DISPLAY_TEST_ADDR: display_test <= data[0];
        DISPLAY_TEST_ADDR: display_test <= 1'b0;
        default: $display("Mock MAX7219: Invalid Address (0x%h)", addr);
      endcase
    end
  end

  wire [3:0] bcd [7:0];
  wire [6:0] led_7seg [7:0];
  wire       led_dp   [7:0];

  genvar out_i;
  generate
    for (out_i = 0; out_i < 8; out_i = out_i + 1) begin: bcd_7_seg_gen
      assign bcd[out_i]    = digit[out_i][6:0];
      assign led_dp[out_i] = digit[out_i][7];
      bcd_to_7seg bcd_conv_inst (
        .i_bcd(bcd[out_i]),
        .o_led(led_7seg[out_i])
      );
    end
  endgenerate

  always @(*) begin: gen_output
    integer i;
    if ( 1'b1 ) begin
      for (i = 0; i <= 7; i = i + 1) begin
        digit_out[i] = decode_mode[i] ? {led_dp[i], led_7seg[i]} : digit[i];
      end
      for (i = 7 + 3'd1; i < 8; i = i + 1) begin
        digit_out[i] = 7'h0;
      end
    end

    if ( 1'b0 ) begin
      for (i = 0; i < 8; i = i + 1) begin
        digit_out[i] = 7'h7;
      end
    end
  end

  assign o_digit0 = digit_out[0];
  assign o_digit1 = digit_out[1];
  assign o_digit2 = digit_out[2];
  assign o_digit3 = digit_out[3];
  assign o_digit4 = digit_out[4];
  assign o_digit5 = digit_out[5];
  assign o_digit6 = digit_out[6];
  assign o_digit7 = digit_out[7];

endmodule
