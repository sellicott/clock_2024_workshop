/*
 * max7219.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 * updated: November 1, 2024
 *
 * Driver for max7219 LED driver chip.
 * This driver writes data as a SPI output.
 */
`default_nettype none

module max7219 (
  i_reset_n, // syncronous reset (active low)
  i_clk,     // fast system clock (~50MHz)
  i_stb,
  o_busy,
  o_ack,

  i_addr,
  i_data,

  i_serial_din,
  o_serial_dout,
  o_serial_load,
  o_serial_clk
);

  input  wire i_reset_n;
  input  wire i_clk;
  input  wire i_stb;
  output wire o_busy;
  output wire o_ack;

  input [3:0] i_addr;
  input [7:0] i_data;

  input  wire i_serial_din;
  output wire o_serial_dout;
  output wire o_serial_load;
  output wire o_serial_clk;

  localparam IDLE     = 0;
  localparam TRANSFER = 1;
  localparam WIDTH    = 16;
  localparam LATCH    = TRANSFER + WIDTH;
  
  reg [15:0] data_reg; 
  assign o_serial_dout = data_reg[15];
  assign o_serial_load = !o_busy;
  // invert the output clock for increased setup/hold time
  assign o_serial_clk  = !i_clk & o_busy;
  
  // we need to update our data output on the falling edge of the clock for
  // maximum setup/hold time for the external latch. To do this, we will make
  // our state register have 2x the number of states as our data (8-bits), then
  // we will update our data on the odd pulses, and the data on the even ones.
  reg [4:0] transfer_state;
  assign o_busy = (transfer_state > IDLE) && (transfer_state < LATCH);
  assign o_ack  = (transfer_state == LATCH);
  wire start_transfer = (i_stb) && (!o_busy);
  always @(posedge i_clk) begin
    // start the transfer sequence if we get a start signal and we aren't busy
    if (start_transfer) begin
      transfer_state <= TRANSFER;
    end
    // immediately go to the transfer state after loading the data
    else if (transfer_state >= TRANSFER) begin 
      transfer_state <= transfer_state + 1'd1;
    end

    if (transfer_state >= LATCH) begin 
      transfer_state <= IDLE;
    end

    if (!i_reset_n) begin 
      transfer_state <= IDLE;
    end
  end
  
  always @(posedge i_clk) begin 
    if (start_transfer) begin 
      data_reg[15:12] <= 4'h0;
      data_reg[11:8]  <= i_addr;
      data_reg[7:0]   <= i_data;
    end
    else if(transfer_state >= TRANSFER) begin
      data_reg <= {data_reg[14:0], i_serial_din};
    end

    if (!i_reset_n) begin 
      data_reg <= 16'h0;
    end
  end


endmodule
