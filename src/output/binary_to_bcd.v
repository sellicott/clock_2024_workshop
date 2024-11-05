
/* binary_to_bcd.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 *
 * Convert 7-bit binary input into two BCD outputs.
 * The highest number we expect to take into the module on the binary input is
 * decimal 99. Larger numbers will produce 
 */

`default_nettype none

module binary_to_bcd (
  i_binary,
  o_bcd_msb,
  o_bcd_lsb
);

input wire [6:0] i_binary;

// these are regs so that we can assign to them in an always block
output reg [3:0] o_bcd_msb;
output reg [3:0] o_bcd_lsb;

wire [9:0] msb_one_hot;
wire [6:0] bin = i_binary;

// our input is in the range [0, 63] meaning, we have 7 possible outputs for
// the msb
assign msb_one_hot[0] =                   (bin < 7'd10);
assign msb_one_hot[1] = (bin >= 7'd10) && (bin < 7'd20);
assign msb_one_hot[2] = (bin >= 7'd20) && (bin < 7'd30);
assign msb_one_hot[3] = (bin >= 7'd30) && (bin < 7'd40);
assign msb_one_hot[4] = (bin >= 7'd40) && (bin < 7'd50);
assign msb_one_hot[5] = (bin >= 7'd50) && (bin < 7'd60);
assign msb_one_hot[6] = (bin >= 7'd60) && (bin < 7'd70);
assign msb_one_hot[7] = (bin >= 7'd70) && (bin < 7'd80);
assign msb_one_hot[8] = (bin >= 7'd80) && (bin < 7'd90);
assign msb_one_hot[9] = (bin >= 7'd90) && (bin < 7'd100);

always @(*) begin
   case(msb_one_hot)
       10'h200: o_bcd_msb = 4'd9;
       10'h100: o_bcd_msb = 4'd8;
       10'h080: o_bcd_msb = 4'd7;
       10'h040: o_bcd_msb = 4'd6;
       10'h020: o_bcd_msb = 4'd5;
       10'h010: o_bcd_msb = 4'd4;
       10'h008: o_bcd_msb = 4'd3;
       10'h004: o_bcd_msb = 4'd2;
       10'h002: o_bcd_msb = 4'd1;
       10'h001: o_bcd_msb = 4'd0;
       default: o_bcd_msb = 4'hF;
   endcase
end

always @(*) begin
   case(o_bcd_msb)
       4'h9: o_bcd_lsb = (bin - 7'd90) & 7'h0f;
       4'h8: o_bcd_lsb = (bin - 7'd80) & 7'h0f;
       4'h7: o_bcd_lsb = (bin - 7'd70) & 7'h0f;
       4'h6: o_bcd_lsb = (bin - 7'd60) & 7'h0f;
       4'h5: o_bcd_lsb = (bin - 7'd50) & 7'h0f;
       4'h4: o_bcd_lsb = (bin - 7'd40) & 7'h0f;
       4'h3: o_bcd_lsb = (bin - 7'd30) & 7'h0f;
       4'h2: o_bcd_lsb = (bin - 7'd20) & 7'h0f;
       4'h1: o_bcd_lsb = (bin - 7'd10) & 7'h0f;
       4'h0: o_bcd_lsb = (bin - 7'd00) & 7'h0f;
       default: o_bcd_lsb = 4'hf;
   endcase
end

endmodule
