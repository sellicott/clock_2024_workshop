
/* refclk_sync.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 *
 * Syncronize reference clock to system clock
 */

`default_nettype none

module refclk_sync (
  // global signals
  i_reset_n,
  i_clk,
  // 32,768 Hz reference clock
  i_refclk,
  // syncronized reference clock output
  o_refclk_sync
);

input wire i_reset_n;
input wire i_clk;

input wire i_refclk;
output wire o_refclk_sync;

// We need to retime the input refclk signal so that we can use it to enable
// the counter
reg [1:0] refclk_sync_reg;

// define a shift register 
always @(posedge i_clk) begin
  refclk_sync_reg <= {refclk_sync_reg[0], i_refclk};
  if (!i_reset_n) begin
    refclk_sync_reg <= 2'h0;
  end
end

assign o_refclk_sync = refclk_sync_reg[1];

endmodule
