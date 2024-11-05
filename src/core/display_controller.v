/* display_controller.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 * updated: November 1, 2024
 *
 * Handle MAX7219 display startup / signal display refresh
 */
`default_nettype none

module display_controller (
    i_reset_n,
    i_clk,

    i_1hz_stb,
    i_clk_set_stb,
    i_clk_set,

    o_display_stb,
    i_display_ack,

    o_write_config
);

  input wire i_reset_n;
  input wire i_clk;

  input wire i_1hz_stb;
  input wire i_clk_set_stb;
  input wire i_clk_set;

  output wire o_display_stb;
  input  wire i_display_ack;

  output wire o_write_config;

  reg startup;
  reg display_update;

  assign o_write_config = startup;
  assign o_display_stb  = display_update;

  always @(posedge i_clk) begin

    // clear the display update if we have already sent the initial settings
    // and we have received acknowledgement from sending the first update
    if (display_update && !startup && i_display_ack) begin
      // clear the forced update on startup
      display_update <= 1'b0;
    end
    // otherwise delay the current update clock by one clock cycle
    else begin
      display_update <= i_clk_set ? i_clk_set_stb : i_1hz_stb;
    end

    // if we get an ack while the startup bit is set,
    // we are done sending settings
    if (startup && i_display_ack) begin
      startup <= 1'b0;
      display_update <= 1'b1;
    end

    // set some flags on reset
    if (!i_reset_n) begin
        startup <= 1'b1;
        display_update <= 1'b1;
    end
  end

endmodule
