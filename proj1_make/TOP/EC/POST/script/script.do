set log file ./log/all.log -replace

read library -verilog -both \
	../../../../../SoC/GPDK045/digital/gsclib045_all_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v \
	../../../../../SoC/GPDK045/digital/gsclib045_all_v4.4/gsclib045/verilog/fast_vdd1v0_basicCells.v \
	../../../../../SoC/GPDK045/digital/giolib045_v3.5/vlog/pads_SS_s1vg.v

// Golden  : synthesis netlist (Vol.1 ch5)
read design ../../SYN/mapped/_UART_TOP_syn_final.v -verilog -golden

// Revised : PnR netlist (Vol.2 ch8, saveNetlist -flat)
read design ../../PNR/_UART_TOP.v -verilog -revised

set system mode lec

add compare points -all

compare

report verification
report statistics
