
/* button_debounce.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 *
 * Button debouncing module. Syncronizes input signals then takes NUM_SAMPLES
 * based on the i_debounce_stb input. If all samples are 1, output 1,
 * otherwise 0.
 * The debounce_stb signal is expected to be about 4KHz, therefore if 
 * NUM_SAMPLES is 5, the button must be bounce free for ~1.25us
 * in order to output 1.
 */

`default_nettype none

module button_debounce (
  // global signals
  i_reset_n,
  i_clk,
  
  // 4.096KHz strobe signal
  i_debounce_stb,
  
  // input buttons
  i_fast_set,
  i_set_hours,
  i_set_minutes,
  
  // debounced outputs
  o_fast_set_db,
  o_set_hours_db,
  o_set_minutes_db
);
// combine 5 samples from the input button
parameter NUM_SAMPLES = 5;

input wire i_reset_n;
input wire i_clk;

input wire i_debounce_stb;
  
input wire i_fast_set;
input wire i_set_hours;
input wire i_set_minutes;

output wire o_fast_set_db;
output wire o_set_hours_db;
output wire o_set_minutes_db;

localparam RESET_VAL = {NUM_SAMPLES+1{1'b0}};
// make pipeline registers for all the button inputs, the first input is used
// for syncronization.
reg [NUM_SAMPLES:0] fast_set_reg;
reg [NUM_SAMPLES:0] set_hours_reg;
reg [NUM_SAMPLES:0] set_minutes_reg;

// pipeline and sample the input signals
always @(posedge i_clk) begin
  if (i_debounce_stb) begin
    fast_set_reg    <= {i_fast_set,    fast_set_reg[NUM_SAMPLES:1]};
    set_hours_reg   <= {i_set_hours,   set_hours_reg[NUM_SAMPLES:1]};
    set_minutes_reg <= {i_set_minutes, set_minutes_reg[NUM_SAMPLES:1]};
  end
  if (!i_reset_n) begin
    fast_set_reg    <= RESET_VAL;
    set_hours_reg   <= RESET_VAL;
    set_minutes_reg <= RESET_VAL;
  end
end

// only output a one or zero if NUM_SAMPLE samples are identical
assign o_fast_set_db    = &fast_set_reg[NUM_SAMPLES-1:0];
assign o_set_hours_db   = &set_hours_reg[NUM_SAMPLES-1:0];
assign o_set_minutes_db = &set_minutes_reg[NUM_SAMPLES-1:0];

endmodule
