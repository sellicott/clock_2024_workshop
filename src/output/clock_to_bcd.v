/* clock_to_bcd.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 * Date: October 30, 2024
 *
 * Convert and multiplex binary clock format into a 7-segment display output.
 * The clock is divided into 6-segments (each corresponding to a decimal digit)
 * that are selected by i_seg_select. Data is selected starting from the MSD
 * (MSD of the hours -> LSD of seconds). Decimal points for each of the
 * 7-segment displays are included in the output, i_dp[5] is the decimal point
 * for the hours MSD, i_dp[0] is the decimal point for seconds LSD.
 * The decimal point is included as o_7seg[7].
 */

`default_nettype none

module clock_to_bcd (
  // input signals from the clock
  i_hours,
  i_minutes,
  i_seconds,
  i_dp,

  // select what part of the clock output to convert
  // 0 -> hours MSD, 5 -> seconds lSD
  i_seg_select,

  // 7-segment display output o_7seg[7] -> decimal point
  o_bcd,
  o_dp
);

input wire [4:0] i_hours;
input wire [5:0] i_minutes;
input wire [5:0] i_seconds;
input wire [5:0] i_dp;

input wire [2:0] i_seg_select;

output wire [3:0] o_bcd;
output wire o_dp;

// generate internal wires that zero out the appropriate signals for the
// binary -> bcd converter
wire [6:0] hours_int   = {2'b0, i_hours};
wire [6:0] minutes_int = {1'h0, i_minutes};
wire [6:0] seconds_int = {1'h0, i_seconds};

// Select from either hours, minutes, or seconds
reg [6:0] time_int;
reg seg_dp;
always @(*) begin
  case (i_seg_select)
    3'h0: begin
      time_int = hours_int;
      seg_dp   = i_dp[5];
    end
    3'h1: begin 
      time_int = hours_int;
      seg_dp   = i_dp[4];
    end
    3'h2: begin
      time_int = minutes_int;
      seg_dp   = i_dp[3];
    end
    3'h3: begin
      time_int = minutes_int;
      seg_dp   = i_dp[2];
    end
    3'h4: begin
      time_int = seconds_int;
      seg_dp   = i_dp[1];
    end
    3'h5: begin 
      time_int = seconds_int;
      seg_dp   = i_dp[0];
    end
    default: begin
      time_int = 7'h3f;
      seg_dp   = 1'b1;
    end
  endcase
end

// Convert the binary format time into two BCD segments
wire [3:0] time_msb;
wire [3:0] time_lsb;
binary_to_bcd time_to_bcd(
  .i_binary(time_int),
  .o_bcd_msb(time_msb),
  .o_bcd_lsb(time_lsb)
);

// select between the MSB and LSB
reg [3:0] seg_bcd;
always @(*) begin
  case (i_seg_select[0])
    1'h0: seg_bcd = time_msb;
    1'h1: seg_bcd = time_lsb;
  endcase
end

assign o_bcd = seg_bcd;
assign o_dp  = seg_dp;

endmodule

