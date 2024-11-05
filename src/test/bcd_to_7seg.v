/* bcd_to_7seg
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 * 
 * date: March 4, 2023
 * modified: October 30, 2024
 *
 * module to convert a bcd coded number into the output for a 7-segment display
 */

`default_nettype none

module bcd_to_7seg (
  i_bcd,
  o_led
);
  
  input wire [3:0] i_bcd;
  output reg [6:0] o_led;

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
    case(i_bcd)
      /*                   abcdefg */
      4'h0    : o_led = 7'b1111110;  // 0
      4'h1    : o_led = 7'b0110000;  // 1
      4'h2    : o_led = 7'b1101101;  // 2
      4'h3    : o_led = 7'b1111001;  // 3
      4'h4    : o_led = 7'b0110011;  // 4
      4'h5    : o_led = 7'b1011011;  // 5
      4'h6    : o_led = 7'b1011111;  // 6
      4'h7    : o_led = 7'b1110000;  // 7
      4'h8    : o_led = 7'b1111111;  // 8
      4'h9    : o_led = 7'b1111011;  // 9
      default : o_led = 7'b0000000;  // default is to output nothing
    endcase
  end
    
endmodule
