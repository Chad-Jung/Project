# Function Simulation (RTL, no delay)

```
./clean.tcl
./run_function.tcl
```

- Testbench : `../TESTBENCH/tb_UART_TOP.v` (self-checking, `TEST PASSED` / `TEST FAILED`)
- Clock     : target 50 MHz (20 ns) → simulated at 14 ns (30% pessimistic)
- Waveform  : `dump/function_sim.shm`, Log : `func_sim.log`
- With `-gui` the run pauses at `$stop` after the summary; type `run` to finish.

## Spec (UART IP Rev 1.0) coverage

| Test | Spec | Checks |
|---|---|---|
| T1  | 6, 8      | reset values : STATUS = 0x05, INT_EN = 0, txd = 1, intr = 0 |
| T2  | 5, 7      | single byte TX → RX loopback, TX line monitor |
| T3  | 4.2       | 8-byte burst = FIFO depth, rx_full |
| T4  | 8, 10     | TX_DATA ignored when full (9 frames sent), RX overrun, data lost, W1C |
| T5  | 7.2, 10   | framing error : byte discarded, sticky flag, interrupt, W1C |
| T6  | 7.2       | false start (noise shorter than half a bit) |
| T7  | 7.2       | 8 back-to-back frames from an external transmitter |
| T8  | 8         | TX empty interrupt |
| T9  | 7.1, 9    | bit widths : data/stop = 16 ticks = 432 clk, start = 15~16 ticks |
| T10 | 8         | RX_DATA read when empty ignored, INT_EN[3:0] only, W-only/undefined read 0 |
| T11 | 8, 10     | RX full interrupt, per-bit W1C, interrupt OR |
