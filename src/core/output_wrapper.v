/* output_wrapper: module to take a time register input and generate serialized output data
 * enable signal will blank the led outputs (shift register will always shift out 0's)
 * author: Samuel Ellicott
 * date: 03-20-23
 */
`default_nettype none

module output_wrapper (
  i_reset_n,
  i_clk,
  i_stb,
  o_busy,
  o_ack,

  i_write_config,

   // input signals from the clock
  i_hours,
  i_minutes,
  i_seconds,
  i_dp,

  // SPI output
  o_serial_dout,
  o_serial_load,
  o_serial_clk
);

  input  wire i_reset_n;
  input  wire i_clk;

  input  wire i_stb;
  output wire o_busy;
  output wire o_ack;

  input wire i_write_config;

  input wire [4:0] i_hours;
  input wire [5:0] i_minutes;
  input wire [5:0] i_seconds;
  input wire [5:0] i_dp;

  output wire o_serial_dout;
  output wire o_serial_load;
  output wire o_serial_clk;

  // Convert the clock output to BCD
  wire [2:0] seg_select;
  wire [3:0] clk_bcd;
  wire       clk_dp;

  reg [4:0] hours_int;
  reg [5:0] minutes_int;
  reg [5:0] seconds_int;

  clock_to_bcd clock_to_bcd_conv_inst (
    // input signals from the clock
    .i_hours   (hours_int),
    .i_minutes (minutes_int),
    .i_seconds (seconds_int),
    .i_dp      (i_dp),

    // select what part of the clock output to convert
    // 0 -> hours MSD, 5 -> seconds lSD
    .i_seg_select (seg_select),

    .o_bcd  (clk_bcd),
    .o_dp   (clk_dp)
  );

  wire [7:0] decode_mode  = 8'hff;
  wire [3:0] intensity    = 4'h7;
  wire [2:0] scan_limit   = 3'h5;
  wire       enable       = 1;
  wire       display_test = 0;

  wire driver_stb;
  wire driver_busy;
  wire driver_ack;

  wire max7219_ack;
  wire max7219_stb;
  wire [3:0] max7219_addr;
  wire [7:0] max7219_data;

  max7219_settings display_settings (
    .i_reset_n (i_reset_n), // syncronous reset (active low)
    .i_clk     (i_clk),     // fast system clock (~50MHz)
    .i_stb     (driver_stb),
    .o_busy    (driver_busy),
    .o_ack     (driver_ack),

    .i_digit   (seg_select),
    .i_segment ({clk_dp, 3'h0, clk_bcd}),

    .i_write_config (i_write_config),
    .i_decode_mode  (decode_mode),
    .i_intensity    (intensity),
    .i_scan_limit   (scan_limit),
    .i_enable       (enable),
    .i_display_test (display_test),

    .i_next  (max7219_ack), // connect to ack line of max7219 driver
    .o_write (max7219_stb), // connect to stb line of max7219 driver
    .o_addr  (max7219_addr),
    .o_data  (max7219_data)
  );

  // iterate through the clock segments
  localparam IDLE = 4'h0;
  localparam WRITE = 4'h1;
  localparam NUM_DIGITS = 4'd6;
  localparam END_WRITE  = WRITE + NUM_DIGITS;

  reg [3:0] state;
  always @(posedge i_clk) begin
    if (i_stb & !o_busy) begin
      // jump to the last write if we are writing the configuration register
      if (!i_write_config) begin
        state <= WRITE;
      end
      else begin
        state <= END_WRITE - 4'd1;
      end
    end
    else if (state >= WRITE && driver_ack) begin
      state <= state + 1'd1;
    end

    if (state >= END_WRITE) begin
      state <= IDLE;
    end

    if (!i_reset_n) begin
      state <= IDLE;
    end
  end

  // add some pipelining for the display output
  always @(posedge i_clk) begin
    if (i_stb & !o_busy) begin
      hours_int <= i_hours;
      minutes_int <= i_minutes;
      seconds_int <= i_seconds;
    end

    if (!i_reset_n) begin
      hours_int <= 5'd0;
      minutes_int <= 6'd0;
      seconds_int <= 6'd0;
    end
    
  end

  assign seg_select = state - WRITE;

  assign driver_stb = (state > IDLE) && !o_ack;
  assign o_busy = (state > IDLE) && (state < END_WRITE);
  assign o_ack  = (state == END_WRITE);

  wire max7219_busy;

  max7219 disp_driver (
    .i_reset_n (i_reset_n),
    .i_clk     (i_clk),
    .i_stb     (max7219_stb),
    .o_busy    (max7219_busy),
    .o_ack     (max7219_ack),

    .i_addr (max7219_addr),
    .i_data (max7219_data),

    .i_serial_din  (1'h0),
    .o_serial_dout (o_serial_dout),
    .o_serial_load (o_serial_load),
    .o_serial_clk  (o_serial_clk)
  );

endmodule
