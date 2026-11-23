# -timescale : To mention the time unit and time precision
# -access : Passed to the elaborator to provide read access to simulation objects
# -gui : To invoke the xrun in gui mode
# -mess : To display all to the messages in detail
# -define : To enable `ifdef blocks in the testbench (function_sim -> $shm_open/$shm_probe)
# -v : To provide library in ".v" format
# +libext : library extention
# +libext+.v -y : xrun would compile .v files automatically in the specific folder decribed with -y option

# Waveform is dumped to ./dump/function_sim.shm (see `ifdef function_sim in tb_UART_TOP.v)
mkdir -p dump
xrun -64bit \
     +max_err_count+50 \
     +define+function_sim \
     -access +rwc \
     -profile \
     -profthread \
     -gui \
     +libext+.v \
     -incdir ../../RTL/UART \
     -incdir ../TESTBENCH \
     -y ../../RTL/UART \
     -y ../TESTBENCH \
     ../TESTBENCH/tb_UART_TOP.v \
     ../../RTL/UART/_UART_TOP.v \
     ../../RTL/UART/_BAUD_GEN_16X.v \
     ../../RTL/UART/_SYNC_FIFO_8x8.v \
     ../../RTL/UART/_UART_TX.v \
     ../../RTL/UART/_UART_RX.v \
     ../../RTL/UART/_UART_REG_IF.v \
     /GPDK045/digital/giolib045_v3.5/vlog/pads_FF_s1vg.v \
     /GPDK045/digital/gsclib045_all_v4.4/gsclib045_svt_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v \
     -l func_sim.log
