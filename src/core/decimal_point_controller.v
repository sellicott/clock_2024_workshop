/* decimal_point_controller.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 * updated: November 1, 2024
 *
 * Generate outputs for display decimal points/colon
 * Toggle colon at 0.5Hz during normal clock operation.
 * Solid on while in time set mode.
 * Decimal point between minutes and seconds on during normal operation
 * Off during time set mode.
 * All other decimal points off. (front DP reserved for AM/PM mode, last DP
 * reserved for alarm enabled/disabled.
 */
`default_nettype none

module decimal_point_controller (
  i_set_time,
  i_seconds,
  o_dp
);
  
  input  wire       i_set_time;
  input  wire [5:0] i_seconds;
  output reg  [5:0] o_dp;

  always @(*) begin
    if (!i_set_time) begin
      o_dp[4:3] = i_seconds[0] ? 2'b11 : 2'b00;
      o_dp[1]   = 1'b1;
    end
    else begin
      o_dp[4:3] = 2'b11;
      o_dp[1]   = 1'b0;
    end
    o_dp[5] = 1'b0;
    o_dp[2] = 1'b0;
    o_dp[0] = 1'b0;
  end

endmodule
