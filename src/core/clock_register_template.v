
/* clock_register.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 *
 * Register for storing the clock time (in 24h format)
 */

`default_nettype none

module clock_register (
  // global signals
  i_reset_n,
  i_clk,

  // timing strobes
  i_1hz_stb,
  i_set_stb,

  // clock setting inputs
  i_set_hours,
  i_set_minutes,

  // time outputs
  o_hours,
  o_minutes,
  o_seconds
);

// global signals
input wire i_reset_n;
input wire i_clk;

// timing strobes
input wire i_1hz_stb;
input wire i_set_stb;

// clock setting inputs
input wire i_set_hours;
input wire i_set_minutes;

// time outputs
output reg [4:0] o_hours;
output reg [5:0] o_minutes;
output reg [5:0] o_seconds;

// TODO: Implement the clock

endmodule
