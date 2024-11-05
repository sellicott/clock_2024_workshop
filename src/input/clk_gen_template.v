
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

// TODO: Implement strobe output signals

endmodule
