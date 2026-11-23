# Function Simulation (RTL, no delay)

```
./clean.tcl
./run_function.tcl
```

- Testbench : `../TESTBENCH/tb_UART_TOP.v` (self-checking, prints `TEST PASSED` / `TEST FAILED`)
- Clock     : target 50 MHz (20 ns) → simulated at 14 ns (30% pessimistic)
- Waveform  : `dump/function_sim.shm`, Log : `func_sim.log`
- `-gui` 없이 batch로 돌리려면 run_function.tcl에서 `-gui` 줄을 지우면 됨
