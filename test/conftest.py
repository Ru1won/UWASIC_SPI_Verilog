import pytest
from cocotb_test.simulator import run
import os

# Equivalent to SRC_DIR = $(PWD)/../src
SRC_DIR = os.path.join(os.path.dirname(__file__), "../src")
TEST_DIR = os.path.dirname(__file__)

# RTL simulation (equivalent to ifneq ($(GATES),yes) block)
@pytest.fixture
def sim_args():
    return dict(
        simulator="icarus",                          # SIM = icarus
        toplevel="tt_um_UWASIC_onboarding_Ruwan_Kadam",  # TOPLEVEL = tb (pointing directly at DUT)
        toplevel_lang="verilog",                     # TOPLEVEL_LANG = verilog
        module="test",                               # MODULE = test
        verilog_sources=[                            # VERILOG_SOURCES
            os.path.join(SRC_DIR, "project.v"),
            os.path.join(SRC_DIR, "pwm_peripheral.v"),
            os.path.join(SRC_DIR, "SPIperipheral.v"),
        ],
        compile_args=[f"-I{SRC_DIR}"],              # COMPILE_ARGS += -I$(SRC_DIR)
        sim_build="sim_build/rtl",                   # SIM_BUILD = sim_build/rtl
    )

def test_spi(sim_args):
    run(**sim_args, testcase="test_spi")

def test_pwm_freq(sim_args):
    run(**sim_args, testcase="test_pwm_freq")

def test_pwm_duty(sim_args):
    run(**sim_args, testcase="test_pwm_duty")