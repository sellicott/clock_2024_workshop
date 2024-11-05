
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

stb_gen stb_gen_refclk (
  .i_reset_n (i_reset_n),
  .i_clk     (i_clk),
  .i_sig     (i_refclk),
  .o_sig_stb (refclk_stb)
);

// we need a register to count the number of pulses from the reference clock
reg [14:0] refclk_div;
always @(posedge i_clk) begin
  if (refclk_stb) begin
    refclk_div <= refclk_div + 1;
  end

  if (!i_reset_n) begin
    refclk_div <= 15'h0;
  end
end

// generate strobe signals off of the clock divider
// 32,768 / 2^15 -> 1hz
stb_gen stb_gen_1hz (
  .i_reset_n (i_reset_n),
  .i_clk     (i_clk),
  .i_sig     (refclk_div[14]),
  .o_sig_stb (o_1hz_stb)
);

// 32,768 / 2^13 -> 2hz
stb_gen stb_gen_slow_clk (
  .i_reset_n (i_reset_n),
  .i_clk     (i_clk),
  .i_sig     (refclk_div[13]),
  .o_sig_stb (o_slow_set_stb)
);

// 32,768 / 2^11 -> 8hz
stb_gen stb_gen_fast_clk (
  .i_reset_n (i_reset_n),
  .i_clk     (i_clk),
  .i_sig     (refclk_div[11]),
  .o_sig_stb (o_fast_set_stb)
);

// 32,768 / 2^3 -> 4096Hz 
stb_gen stb_gen_debounce_clk (
  .i_reset_n (i_reset_n),
  .i_clk     (i_clk),
  .i_sig     (refclk_div[3]),
  .o_sig_stb (o_debounce_stb)
);

endmodule

// generate a single system clock pulse (o_sig_stb)
// on the rising edge of i_sig.
module stb_gen (
  // global signals
  i_reset_n,
  i_clk,

  // input signal to generate strobe signal off rising edge
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
    sig_hold <= 1'h0;
  end
end

assign o_sig_stb = i_sig & ~sig_hold;

endmodule

