/* test_7seg_to_bcd 
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 * 
 * date: March 4, 2023
 * modified: October 30, 2024
 *
 * module to convert a output for a 7-segment display to bcd
 * this is used for testing led output
 */

`default_nettype none

module test_7seg_to_bcd (
  i_led,
  o_bcd
);
  
  input wire [6:0] i_led;
  output reg [3:0] o_bcd;

  /* 
   *   aaa
   *  f   b
   *  f   b
   *   ggg
   *  e   c
   *  e   c
   *   ddd  
   */
  always @(*) begin
      case(i_led)
        7'b1111110: o_bcd = 4'd0;  // 0
        7'b0110000: o_bcd = 4'd1;  // 1
        7'b1101101: o_bcd = 4'd2;  // 2
        7'b1111001: o_bcd = 4'd3;  // 3
        7'b0110011: o_bcd = 4'd4;  // 4
        7'b1011011: o_bcd = 4'd5;  // 5
        7'b1011111: o_bcd = 4'd6;  // 6
        7'b1110000: o_bcd = 4'd7;  // 7
        7'b1111111: o_bcd = 4'd8;  // 8
        7'b1111011: o_bcd = 4'd9;  // 9
        default :   o_bcd = 4'hf;  // default is to output nothing
      endcase
  end
    
endmodule
