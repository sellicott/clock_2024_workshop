
/* clk_gen.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 *
 * Generate pulse signals with appropriate timings. This block assumes there
 * is a 32,768 Hz signal coming in on the i_refclk input (that has been
 * appropriately retimed), this will be divided approprately to generate a
 * 1 clk wide pulse for:
 * 1 Hz <= main clock
 * 2 Hz <= slow set clock
 * 8 Hz <= fast set clock
 *
 * The system clock just needs to be somewhat faster than the refclk input
 * (I'm assuming ~%MHz).
 */

`default_nettype none

module clk_gen (
  // global signals
  i_reset_n,
  i_clk,
  // Strobe from 32,768 Hz reference clock
  i_refclk,
  // output strobe signals
  o_1hz_stb,      // refclk / 2^15 -> 1Hz
  o_slow_set_stb, // refclk / 2^14 -> 2Hz
  o_fast_set_stb, // refclk / 2^12 -> 8Hz
  o_debounce_stb  // refclk / 2^4  -> 4.096KHz
);

input wire i_reset_n;
input wire i_clk;
input wire i_refclk;

output wire o_1hz_stb;
output wire o_slow_set_stb;
output wire o_fast_set_stb;
output wire o_debounce_stb;

wire refclk_stb;

stb_gen refclk_stb_inst (
  .i_reset_n(i_reset_n),
  .i_clk(i_clk),

  .i_sig(i_refclk),
  .o_sig_stb(refclk_stb)
);

reg [14:0] counter;
always @(posedge i_clk) begin
  if (refclk_stb) begin
    counter <= counter + 15'd1;
  end
  if (!i_reset_n) begin
    counter <= 15'd0;
  end
end

assign o_1hz_stb = counter[2];

endmodule

module stb_gen (
  i_reset_n,
  i_clk,

  i_sig,
  o_sig_stb
);

input wire i_reset_n;
input wire i_clk;
input wire i_sig;
output wire o_sig_stb;

reg sig_hold;
always @(posedge i_clk) begin
  sig_hold <= i_sig;
  if (!i_reset_n) begin
    sig_hold <= 1'b0;
  end
end

assign o_sig_stb = i_sig & ~sig_hold;

endmodule
