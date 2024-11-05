/*
 * clock_wrapper.v
 * Copyright (c) 2024 Samuel Ellicott
 * SPDX-License-Identifier: Apache-2.0
 * date: November 03, 2023
 * updated: October 30, 2024
 *
 * Wrap all the important bits of the clock for tiny tapeout
 * This includes the
 * - button debouncing
 * - time register
 * - binary to BCD converter
 * - MAX7219 Display Driver
 */
`default_nettype none

module clock_wrapper (
  // global signals
  i_reset_n,      // syncronous reset (active low)
  i_clk,          // fast system clock (~10MHz)
  i_en,           // enable the project (always 1)

  // Clock inputs
  i_refclk,       // 32.768 kHz clock

  i_fast_set,     // select the timeset speed (1 for fast, 0 for slow)
  i_set_hours,    // stop updating time (from refclk) and set hours
  i_set_minutes,  // stop updating time (from refclk) and set minutes

  // Clock SPI Output to MAX7219
  o_serial_load,  // SPI _CS_ pin
  o_serial_dout,  // SPI MOSI pin
  o_serial_clk    // SPI SCK pin
);
  
  input wire i_reset_n;
  input wire i_clk;
  input wire i_en;

  input wire i_refclk;

  input wire i_fast_set;
  input wire i_set_hours;
  input wire i_set_minutes;
  
  output wire o_serial_load;
  output wire o_serial_dout;
  output wire o_serial_clk;

  // Syncronize the refclk input to the system clock 
  wire refclk_sync;

  refclk_sync refclk_sync_inst (
    .i_reset_n     (i_reset_n),
    .i_clk         (i_clk),
    .i_refclk      (i_refclk),
    .o_refclk_sync (refclk_sync)
  );

  // generate strobe signals for updating the clock
  wire clk_1hz_stb;
  wire clk_slow_set_stb;
  wire clk_fast_set_stb;
  wire clk_debounce_stb;

  clk_gen clk_gen_inst (
    .i_reset_n      (i_reset_n),
    .i_clk          (i_clk),
    .i_refclk       (refclk_sync),
    .o_1hz_stb      (clk_1hz_stb),
    .o_slow_set_stb (clk_slow_set_stb),
    .o_fast_set_stb (clk_fast_set_stb),
    .o_debounce_stb (clk_debounce_stb)
  );

  // Debounce button inputs
  wire clk_fast_set;
  wire clk_set_hours;
  wire clk_set_minutes;

  button_debounce input_debounce (
    .i_reset_n (i_reset_n),
    .i_clk     (i_clk),
    
    .i_debounce_stb (clk_debounce_stb),
    
    .i_fast_set    (i_fast_set),
    .i_set_hours   (i_set_hours),
    .i_set_minutes (i_set_minutes),
    
    .o_fast_set_db    (clk_fast_set),
    .o_set_hours_db   (clk_set_hours),
    .o_set_minutes_db (clk_set_minutes)
  );

  // Modules for holding the time
  wire [4:0] clk_hours;
  wire [5:0] clk_minutes;
  wire [5:0] clk_seconds;
  wire [5:0] clk_dp; // decimal points for the displays

  // select between setting the clock at 6Hz or 2Hz
  wire clk_set_stb = clk_fast_set ? clk_fast_set_stb : clk_slow_set_stb;

  // test if we are setting the clock or running the clock 
  wire clk_set = clk_set_hours || clk_set_minutes;

  clock_register clock_reg_inst (
    // global signals
    .i_reset_n (i_reset_n),
    .i_clk     (i_clk),

    // timing strobes
    .i_1hz_stb (clk_1hz_stb),
    .i_set_stb (clk_set_stb),

    // clock setting inputs
    .i_set_hours   (clk_set_hours),
    .i_set_minutes (clk_set_minutes),

    // time outputs
    .o_hours   (clk_hours),
    .o_minutes (clk_minutes),
    .o_seconds (clk_seconds)
  );


  // Take the time and display it on the 7-segment displays
  wire display_stb;
  wire display_busy;
  wire display_ack;
  wire write_config;

  // blink the colon at 0.5Hz if the clock is running
  decimal_point_controller dp_control_inst (
    .i_set_time (clk_set),
    .i_seconds  (clk_seconds),
    .o_dp       (clk_dp) 
  );

  // override display updates on clock reset in order to
  // write the MAX7219 configuration registers
  // if we are setting the clock, update the display on
  // clk_set_stb signal instead of 1hz signal
  display_controller display_control_inst (
    .i_reset_n (i_reset_n),
    .i_clk     (i_clk),

    .i_1hz_stb     (clk_1hz_stb),
    .i_clk_set_stb (clk_set_stb),
    .i_clk_set     (clk_set),

    .o_display_stb (display_stb),
    .i_display_ack (display_ack),

    .o_write_config (write_config)
  );

  // MAX7219 SPI Output driver
  output_wrapper display_inst (
    .i_reset_n (i_reset_n),
    .i_clk     (i_clk),
    .i_stb     (display_stb),
    .o_busy    (display_busy),
    .o_ack     (display_ack),

    .i_write_config (write_config),

    // input signals from the clock
    .i_hours   (clk_hours),
    .i_minutes (clk_minutes),
    .i_seconds (clk_seconds),
    .i_dp      (clk_dp),

    // SPI output
    .o_serial_dout (o_serial_dout),
    .o_serial_load (o_serial_load),
    .o_serial_clk  (o_serial_clk)
  );

endmodule
