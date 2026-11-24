# -timescale : To mention the time unit and time precision
# -access : Passed to the elaborator to provide read access to simulation objects
# -gui : To invoke the xrun in gui mode
# -mess : To display all to the messages in detail
# -define : To provide SDF definition present in the testbench file
# -v : To provide library in ".v" format
# +libext : library extention
# +libext+.v -y : xrun would compile .v files automatically in the specific folder decribed with -y option 

# Post-layout (min corner) : PnR hierarchical netlist + Tempus SDF (_UART_TOP_post_bst.sdf)
# SDF is annotated at ../../TESTBENCH/tb_UART_TOP.v (`ifdef sdf_gate / post_min)
# SDF corner and cell model corner must match : fast cells / pads_FF
cp ../../../PNR/_UART_TOP_hier.v .
cp ../../../PNR/_UART_TOP_post_bst.sdf .

xrun -64bit \
     +max_err_count+50 \
     +define+sdf_gate+post_min \
     -access +rwc \
     -profile \
     -profthread \
     -gui \
     +libext+.v \
     ../../TESTBENCH/tb_UART_TOP.v \
     _UART_TOP_hier.v \
     ../../../../../../SoC/GPDK045/digital/giolib045_v3.5/vlog/pads_FF_s1vg.v \
     ../../../../../../SoC/GPDK045/digital/gsclib045_all_v4.4/gsclib045_svt_v4.4/gsclib045/verilog/fast_vdd1v0_basicCells.v \
     -l post_sim_min.log
