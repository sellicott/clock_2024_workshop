# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.triggers import RisingEdge 


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")
    dut._log.info("Run tests in Icarus Verilog")

    clock = Clock(dut.clk_dummy, 10, units="us")
    cocotb.start_soon(clock.start())



    # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk_dummy, 1)

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    await RisingEdge(dut.test_done)

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
