# -timescale : To mention the time unit and time precision
# -access : Passed to the elaborator to provide read access to simulation objects
# -gui : To invoke the xrun in gui mode
# -mess : To display all to the messages in detail
# -define : To provide SDF definition present in the testbench file
# -v : To provide library in ".v" format
# +libext : library extention
# +libext+.v -y : xrun would compile .v files automatically in the specific folder decribed with -y option 

# SDF file is annotated at ../TESTBENCH/tb_UART_TOP.v (`ifdef sdf_gate)
cp ../../SYN/mapped/_UART_TOP_syn_final.v .
cp ../../SYN/mapped/_UART_TOP_delays.sdf .

xrun -64bit \
     +max_err_count+50 \
     +define+sdf_gate \
     -access +rwc \
     -profile \
     -profthread \
     -gui \
     +libext+.v \
     ../TESTBENCH/tb_UART_TOP.v \
     _UART_TOP_syn_final.v \
     ../../../../../SoC/GPDK045/digital/giolib045_v3.5/vlog/pads_FF_s1vg.v \
     ../../../../../SoC/GPDK045/digital/gsclib045_all_v4.4/gsclib045_svt_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v \
     -l pre_sim.log
