import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock

@cocotb.test()
async def stupidtest(dut):
    cocotb.start_soon(Clock(dut.clk, 37, unit="ns").start())
    dut.resetn.value = 0
    await ClockCycles(dut.clk, 4)
    dut.resetn.value = 1
    await ClockCycles(dut.clk, 10000000)