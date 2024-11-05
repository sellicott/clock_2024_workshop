/*
 * tt_um_digital_clock_example.v
 * Top level module for the digital clock deisgn
 * Wraps the actual design for use with the TinyTapeout4 template
 */
`default_nettype none

module tt_um_digital_clock_example (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock ~ 10MHz
    input  wire       rst_n     // reset_n - low to reset
);

  wire i_refclk      = ui_in[0];
  wire i_fast_set    = ui_in[2];
  wire i_set_hours   = ui_in[3];
  wire i_set_minutes = ui_in[4];

  wire o_serial_dout;
  wire o_serial_load;
  wire o_serial_clk;

  assign uio_out[0]   = o_serial_load;  // CS line
  assign uio_out[1]   = o_serial_dout;  // MOSI line
  assign uio_out[2]   = 1'b0;
  assign uio_out[3]   = o_serial_clk;  // SCK line
  assign uio_out[7:4] = 4'h0;

  // deal with the pins we aren't using currently
  assign uo_out[7:0]  = 8'h0;
  assign uio_oe[7:0]  = 8'h0B;

  clock_wrapper desk_clock (
      .i_reset_n (rst_n),
      .i_clk     (clk),
      .i_refclk  (i_refclk),
      .i_en      (ena),

      .i_fast_set    (i_fast_set),
      .i_set_hours   (i_set_hours),
      .i_set_minutes (i_set_minutes),

      .o_serial_dout (o_serial_dout),
      .o_serial_load (o_serial_load),
      .o_serial_clk  (o_serial_clk)
  );

endmodule
