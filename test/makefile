SRC_DIR = $(PWD)/../src

# List of testbenches to run automatically
SRC_TESTBENCHES := clk_gen_tb.v
SRC_TESTBENCHES += button_debounce_tb.v
SRC_TESTBENCHES += clock_register_tb.v
SRC_TESTBENCHES += binary_to_bcd_tb.v
SRC_TESTBENCHES += bcd_to_7seg_tb.v
SRC_TESTBENCHES += clock_to_bcd_tb.v
SRC_TESTBENCHES += max7219_tb.v
SRC_TESTBENCHES += max7219_settings_tb.v
SRC_TESTBENCHES += output_wrapper_tb.v
SRC_TESTBENCHES += display_controller_tb.v
SRC_TESTBENCHES += clock_wrapper_tb.v
SRC_TESTBENCHES += tiny_tapeout_tb.v

# Generate lists of output files from the list of testbenches
TESTBENCH_FST = $(SRC_TESTBENCHES:.v=.fst)
TESTBENCH_LOG = $(SRC_TESTBENCHES:.v=.log)
TESTBENCH_SIM = $(basename $(SRC_TESTBENCHES))
.PHONY: $(TESTBENCH_SIM) all clean

# For doing gate level simulation
PDK_ROOT = $(HOME)/.volare
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=\#1

# What to do when just "make" is run
# Build all the testbench output dump files
all: $(TESTBENCH_FST)
	cat $(TESTBENCH_LOG) > logfile.txt

# Rules for compiling each testbench (how to generate a elaborated netlist ".vvp" file)
# The TESTBENCH_FST variable genenerates a list of elaborated files from the list of 
# testbenches
tiny_tapeout_gl_tb.vvp: tiny_tapeout_tb.v \
  $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v \
  $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v \
  tt_um_digital_clock_example.v \
  $(SRC_DIR)/input/refclk_sync.v \
  $(SRC_DIR)/input/clk_gen.v \
  $(SRC_DIR)/test/bcd_to_7seg.v \
  $(SRC_DIR)/test/test_max7219_moc.v \
  $(SRC_DIR)/test/test_7seg_to_bcd.v
	iverilog -o $@ $(COMPILE_ARGS) $^

tiny_tapeout_tb.vvp: tiny_tapeout_tb.v \
  $(SRC_DIR)/tt_um_digital_clock_example.v \
  $(SRC_DIR)/clock_wrapper.v \
  $(SRC_DIR)/input/refclk_sync.v \
  $(SRC_DIR)/input/clk_gen.v \
  $(SRC_DIR)/input/button_debounce.v \
  $(SRC_DIR)/core/clock_register.v \
  $(SRC_DIR)/core/decimal_point_controller.v \
  $(SRC_DIR)/core/display_controller.v \
  $(SRC_DIR)/core/output_wrapper.v \
  $(SRC_DIR)/output/clock_to_bcd.v \
  $(SRC_DIR)/output/binary_to_bcd.v \
  $(SRC_DIR)/output/max7219_settings.v \
  $(SRC_DIR)/output/max7219.v \
  $(SRC_DIR)/test/bcd_to_7seg.v \
  $(SRC_DIR)/test/test_max7219_moc.v \
  $(SRC_DIR)/test/test_7seg_to_bcd.v
	iverilog -o $@ $^

clock_wrapper_tb.vvp: clock_wrapper_tb.v \
  $(SRC_DIR)/clock_wrapper.v \
  $(SRC_DIR)/input/refclk_sync.v \
  $(SRC_DIR)/input/clk_gen.v \
  $(SRC_DIR)/input/button_debounce.v \
  $(SRC_DIR)/core/clock_register.v \
  $(SRC_DIR)/core/decimal_point_controller.v \
  $(SRC_DIR)/core/display_controller.v \
  $(SRC_DIR)/core/output_wrapper.v \
  $(SRC_DIR)/output/clock_to_bcd.v \
  $(SRC_DIR)/output/binary_to_bcd.v \
  $(SRC_DIR)/output/max7219_settings.v \
  $(SRC_DIR)/output/max7219.v \
  $(SRC_DIR)/test/bcd_to_7seg.v \
  $(SRC_DIR)/test/test_max7219_moc.v \
  $(SRC_DIR)/test/test_7seg_to_bcd.v
	iverilog -o $@ $^

display_controller_tb.vvp: display_controller_tb.v \
  $(SRC_DIR)/core/display_controller.v \
  $(SRC_DIR)/input/refclk_sync.v \
  $(SRC_DIR)/input/clk_gen.v \
  $(SRC_DIR)/core/output_wrapper.v \
  $(SRC_DIR)/output/clock_to_bcd.v \
  $(SRC_DIR)/output/binary_to_bcd.v \
  $(SRC_DIR)/output/max7219_settings.v \
  $(SRC_DIR)/output/max7219.v
	iverilog -o $@ $^

output_wrapper_tb.vvp: output_wrapper_tb.v \
  $(SRC_DIR)/core/output_wrapper.v \
  $(SRC_DIR)/output/clock_to_bcd.v \
  $(SRC_DIR)/output/binary_to_bcd.v \
  $(SRC_DIR)/output/max7219_settings.v \
  $(SRC_DIR)/output/max7219.v \
  $(SRC_DIR)/test/bcd_to_7seg.v \
  $(SRC_DIR)/test/test_max7219_moc.v \
  $(SRC_DIR)/test/test_7seg_to_bcd.v
	iverilog -o $@ $^

max7219_settings_tb.vvp: max7219_settings_tb.v \
  $(SRC_DIR)/output/max7219_settings.v \
  $(SRC_DIR)/output/max7219.v
	iverilog -o $@ $^

max7219_tb.vvp: max7219_tb.v \
  $(SRC_DIR)/output/max7219.v \
  $(SRC_DIR)/test/bcd_to_7seg.v \
  $(SRC_DIR)/test/test_max7219_moc.v \
  $(SRC_DIR)/test/test_7seg_to_bcd.v
	iverilog -o $@ $^

bcd_to_7seg_tb.vvp: bcd_to_7seg_tb.v \
  $(SRC_DIR)/test/bcd_to_7seg.v
	iverilog -o $@ $^

clock_to_bcd_tb.vvp: clock_to_bcd_tb.v \
  $(SRC_DIR)/output/clock_to_bcd.v \
  $(SRC_DIR)/output/binary_to_bcd.v
	iverilog -o $@ $^

binary_to_bcd_tb.vvp: binary_to_bcd_tb.v \
  $(SRC_DIR)/output/binary_to_bcd.v
	iverilog -o $@ $^

clock_register_tb.vvp: clock_register_tb.v \
  $(SRC_DIR)/core/clock_register.v \
  $(SRC_DIR)/input/button_debounce.v \
  $(SRC_DIR)/input/refclk_sync.v \
  $(SRC_DIR)/input/clk_gen.v
	iverilog -o $@ $^

button_debounce_tb.vvp: button_debounce_tb.v \
  $(SRC_DIR)/input/button_debounce.v \
  $(SRC_DIR)/input/refclk_sync.v \
  $(SRC_DIR)/input/clk_gen.v
	iverilog -o $@ $^

clk_gen_tb.vvp: clk_gen_tb.v \
  $(SRC_DIR)/input/refclk_sync.v \
  $(SRC_DIR)/input/clk_gen.v
	iverilog -o $@ $^

# Generate output files from elaborated simulation
%.vcd: %.vvp
	vvp $^

%.fst : %.vvp
	vvp $^ -fst | tee $*.log

# run gtkwave on a simulation output file
% : %.fst
	-gtkwave -o $< $@.gtkw &

clean:
	-rm *.vcd
	-rm *.vvp
	-rm *.fst
	-rm *.log
	-rm results.xml
	-rm logfile.txt
