
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

// timeset options are mutually exclusive
// 1) set hours when set hours is pressed (and set minutes isn't)
// 2) set minutes when  set_minutes is pressed (and set hours isn't)
// 3) reset seconds when set_hours and set_minutes are pressed
wire set_hours     = i_set_hours   && ~i_set_minutes;
wire set_minutes   = i_set_minutes && ~i_set_hours;
wire reset_seconds = i_set_hours   && i_set_minutes;
wire timeset_mode  = i_set_hours   || i_set_minutes;

// time outputs
output reg [4:0] o_hours;
output reg [5:0] o_minutes;
output reg [5:0] o_seconds;

wire ovf_seconds = (o_seconds >= 59) && i_1hz_stb;
wire ovf_minutes = (o_minutes >= 59) && ovf_seconds;
wire ovf_hours   = (o_hours   >= 23) && ovf_minutes;

wire hours_stb = (timeset_mode) ?
  ( (set_hours) ? i_set_stb : 1'h0 )
  : ovf_minutes;

wire minutes_stb = (timeset_mode) ?
  ( (set_minutes) ? i_set_stb : 1'h0 )
  : ovf_seconds;

localparam RESET_HOURS   = 5'b0;
localparam RESET_MINUTES = 6'h0;
localparam RESET_SECONDS = 6'h0;

// hours register
always @(posedge i_clk) begin
  // normal operating mode (lowest priority)
  if (hours_stb) begin
    if (ovf_hours)
      o_hours <= RESET_HOURS;
    else 
      o_hours <= o_hours + 5'h1;
  end

  if (o_hours > 23) begin
      o_hours <= RESET_HOURS;
  end

  // reset register (highest priority)
  if (!i_reset_n) begin
    o_hours <= RESET_HOURS;
  end
end

// minutes register
always @(posedge i_clk) begin
  // normal operating mode (lowest priority)
  if (minutes_stb) begin
    if (ovf_minutes)
      o_minutes <= RESET_MINUTES;
    else
      o_minutes <= o_minutes + 6'h1;
  end

  if (o_minutes > 59) begin
      o_minutes <= RESET_MINUTES;
  end


  // reset register (highest priority)
  if (!i_reset_n) begin
    o_minutes <= RESET_MINUTES;
  end
end

// seconds register
always @(posedge i_clk) begin
  // normal operating mode (lowest priority)
  if (i_1hz_stb) begin
    if (ovf_seconds)
      o_seconds <= RESET_SECONDS;
    else
      o_seconds <= o_seconds + 6'h1;
  end

  if (o_seconds > 59) begin
      o_seconds <= RESET_SECONDS;
  end

  // reset register (highest priority)
  if (!i_reset_n || reset_seconds) begin
    o_seconds <= RESET_SECONDS;
  end
end

endmodule
