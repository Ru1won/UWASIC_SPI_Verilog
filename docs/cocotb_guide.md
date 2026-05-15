# CocoTB Syntax Guide
### Specifically for your `test.py`

---

## 1. Imports

```python
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Timer
from cocotb.types import Logic, LogicArray
from cocotb.utils import get_sim_time
```

| Import | What it is |
|--------|-----------|
| `cocotb` | The main library |
| `Clock` | Helper to generate a clock signal |
| `RisingEdge` | Trigger — wait until a signal goes 0→1 |
| `FallingEdge` | Trigger — wait until a signal goes 1→0 |
| `ClockCycles` | Trigger — wait for N clock cycles |
| `Timer` | Trigger — wait for a fixed amount of simulation time |
| `Logic` | Represents a single bit (0, 1, X, Z) |
| `LogicArray` | Represents a multi-bit signal |
| `get_sim_time` | Returns the current simulation time |

---

## 2. Defining a Test

```python
@cocotb.test()
async def my_test_name(dut):
    ...
```

- `@cocotb.test()` — tells CocoTB "this is a test, run it automatically"
- `async` — required because tests use `await` to pause and wait
- `dut` — always the first and only argument, represents your Verilog top module
- The function name becomes the test name in the output log

### Optional: skip a test conditionally
```python
@cocotb.test(skip=some_condition)
async def my_test(dut):
    ...
```

---

## 3. The Clock

```python
clock = Clock(dut.clk, 100, units="ns")
cocotb.start_soon(clock.start())
```

| Part | Meaning |
|------|---------|
| `dut.clk` | Which signal to drive as the clock |
| `100` | Period of one full cycle |
| `units="ns"` | Unit of the period (ns, us, ms) |
| `cocotb.start_soon(...)` | Run the clock in the background, don't wait for it to finish |

`100ns` period = 10 MHz. Change the number to change the clock speed.

---

## 4. Driving Signals

```python
dut.rst_n.value = 0       # drive a single bit signal
dut.ena.value = 1
dut.ui_in.value = some_logicarray   # drive a multi-bit signal
```

- Access any signal with `dut.signal_name.value`
- Assign using `=` (not `<=` like Verilog)
- For multi-bit signals, assign a `LogicArray` or a plain `int`

---

## 5. Reading Signals

```python
val = dut.uo_out.value        # read current value
print(val)                    # prints e.g. 11110000
int(dut.uo_out.value)         # convert to integer
```

Used in assertions to check outputs after a transaction.

---

## 6. Waiting — the `await` keyword

`await` pauses the test and lets simulation time pass. You MUST use `await` to advance time — without it everything happens at time 0.

### Wait for N clock cycles
```python
await ClockCycles(dut.clk, 5)    # wait 5 rising edges of dut.clk
await ClockCycles(dut.clk, 1000) # wait 1000 cycles
```
Used in your testbench after reset and after transactions to let the design settle.

### Wait for a fixed time
```python
await Timer(10, unit="ns")   # wait exactly 10 nanoseconds
await Timer(5, unit="us")    # wait 5 microseconds
```
Used inside `await_half_sclk` to time the SPI clock period.

### Wait for a signal edge
```python
await RisingEdge(dut.clk)        # wait until clk goes 0→1
await FallingEdge(dut.clk)       # wait until clk goes 1→0
await RisingEdge(dut.uo_out)     # wait until any output bit goes high
await FallingEdge(dut.uo_out)    # wait until any output bit goes low
```
You will need these in `test_pwm_freq` and `test_pwm_duty` to detect PWM edges.

---

## 7. Running Something in the Background

```python
cocotb.start_soon(some_async_function(dut))
```

Launches an `async` function concurrently — it runs alongside your test instead of blocking it. Used for:
- Starting the clock: `cocotb.start_soon(clock.start())`
- Starting a clock generator: `cocotb.start_soon(generate_clock(dut))`

---

## 8. Assertions

```python
assert dut.uo_out.value == 0xF0, f"Expected 0xF0, got {dut.uo_out.value}"
```

- `assert condition` — if condition is False, the test fails
- The string after the comma is the error message printed on failure
- `f"..."` is a Python f-string — lets you embed variables inside `{}`

Common patterns in your testbench:
```python
assert dut.uo_out.value == 0xF0           # check exact value
assert dut.uio_out.value == 0xCC          # check another output
assert int(dut.uo_out.value) == 0xF0      # convert then check
```

---

## 9. LogicArray

```python
from cocotb.types import LogicArray

LogicArray("00000100")   # 8-bit value, MSB on left
```

Used in your testbench to pack multiple signals into one bus:
```python
def ui_in_logicarray(ncs, bit, sclk):
    return LogicArray(f"00000{ncs}{bit}{sclk}")
#                             [2]  [1]  [0]
```

Each character in the string is one bit. Valid characters: `0`, `1`, `X`, `Z`.

### Converting a LogicArray
```python
val = dut.uo_out.value
int(val)          # to integer
val.binstr        # to binary string e.g. "11110000"
val[0]            # single bit (LSB)
val[7]            # single bit (MSB)
```

---

## 10. Logging

```python
dut._log.info("Some message here")
dut._log.info("Value is %s", dut.uo_out.value)
```

Prints messages to the terminal during simulation. Use instead of `print()`.

---

## 11. Getting Simulation Time

```python
from cocotb.utils import get_sim_time

t = cocotb.utils.get_sim_time(units="ns")   # returns current time in ns
```

Used to measure how long something takes — critical for `test_pwm_freq` and `test_pwm_duty`:

```python
# Measure time between two events
t1 = cocotb.utils.get_sim_time(units="ns")
await RisingEdge(dut.uo_out)
t2 = cocotb.utils.get_sim_time(units="ns")

elapsed = t2 - t1
```

---

## 12. Calling Helper Functions

Any `async` function must be called with `await`:
```python
# async helper → needs await
ui_in_val = await send_spi_transaction(dut, 1, 0x00, 0xF0)

# regular function → no await needed
val = ui_in_logicarray(1, 0, 0)
```

---

## 13. Full Test Template

Every test in your file follows this exact structure:

```python
@cocotb.test()
async def test_name(dut):
    dut._log.info("Start test")

    # --- STEP 1: Start clock ---
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # --- STEP 2: Reset ---
    dut.ena.value = 1
    dut.ui_in.value = ui_in_logicarray(1, 0, 0)  # idle SPI bus
    dut.rst_n.value = 0                            # activate reset
    await ClockCycles(dut.clk, 5)                 # hold reset
    dut.rst_n.value = 1                            # release reset
    await ClockCycles(dut.clk, 5)                 # settling time

    # --- STEP 3: Send SPI transactions ---
    await send_spi_transaction(dut, 1, 0x00, 0x01)  # write address, data

    # --- STEP 4: Check outputs ---
    assert dut.uo_out.value == 0x01, f"Got {dut.uo_out.value}"

    # --- STEP 5: Wait / measure ---
    await ClockCycles(dut.clk, 1000)

    dut._log.info("Test completed successfully")
```

---

## 14. What You Need for the Blank Tests

### For `test_pwm_freq` — measuring frequency

```python
# Record time at first rising edge
await RisingEdge(dut.uo_out)
t1 = cocotb.utils.get_sim_time(units="ns")

# Record time at next rising edge
await RisingEdge(dut.uo_out)
t2 = cocotb.utils.get_sim_time(units="ns")

# Calculate
period_ns = t2 - t1
frequency_hz = 1e9 / period_ns   # convert ns to seconds
```

### For `test_pwm_duty` — measuring duty cycle

```python
# Wait for signal to go high
await RisingEdge(dut.uo_out)
t_rise = cocotb.utils.get_sim_time(units="ns")

# Wait for signal to go low
await FallingEdge(dut.uo_out)
t_fall = cocotb.utils.get_sim_time(units="ns")

# Wait for next rising edge (end of one full period)
await RisingEdge(dut.uo_out)
t_next_rise = cocotb.utils.get_sim_time(units="ns")

# Calculate
high_time = t_fall - t_rise
period    = t_next_rise - t_rise
duty_cycle_percent = (high_time / period) * 100
```

---

## 15. SPI Register Address Map (your project)

| Address | Register | What it controls |
|---------|----------|-----------------|
| `0x00` | `en_reg_out_7_0` | Output enable for bits 7-0 |
| `0x01` | `en_reg_out_15_8` | Output enable for bits 15-8 |
| `0x02` | `en_reg_pwm_7_0` | PWM enable for bits 7-0 |
| `0x03` | `en_reg_pwm_15_8` | PWM enable for bits 15-8 |
| `0x04` | `pwm_duty_cycle` | Duty cycle for all PWM bits |

To enable PWM output on bit 0 at 50% duty cycle:
```python
await send_spi_transaction(dut, 1, 0x00, 0x01)  # output enable bit 0
await send_spi_transaction(dut, 1, 0x02, 0x01)  # pwm enable bit 0
await send_spi_transaction(dut, 1, 0x04, 0x80)  # 50% duty cycle
```
