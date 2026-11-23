set log file ./log/all.log -replace

read library -verilog -both \
	../../../SoC/GPDK045/digital/gsclib045_all_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v \
	../../../SoC/GPDK045/digital/gsclib045_all_v4.4/gsclib045/verilog/fast_vdd1v0_basicCells.v \
	../../../SoC/GPDK045/digital/giolib045_v3.5/vlog/pads_SS_s1vg.v

read design ../RTL/UART/_UART_TOP.v ../RTL/UART/_BAUD_GEN_16X.v ../RTL/UART/_SYNC_FIFO_8x8.v ../RTL/UART/_UART_TX.v ../RTL/UART/_UART_RX.v ../RTL/UART/_UART_REG_IF.v -verilog -golden

read design ../SYN/mapped/_UART_TOP_syn_final.v -verilog -revised

set system mode lec

add compare points -all

compare

report verification
report statistics

