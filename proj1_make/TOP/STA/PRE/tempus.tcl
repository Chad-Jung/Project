
## Pre-layout STA (synthesized netlist, no parasitics)
## Practice 0. of the lab tempus.tcl, with the SET UP part changed to read
## the synthesis results instead of the PnR database (RouteDesign.dat)

################
### SET UP #####
################
set PDK  ../../../../../SoC/GPDK045/digital
set SYN  ../../SYN/mapped

# max library = worst corner (setup), min library = best corner (hold)
read_lib -max $PDK/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib \
              $PDK/giolib045_v3.5/timing/pads_SS_s1vg.lib \
         -min $PDK/gsclib045_all_v4.4/gsclib045/timing/fast_vdd1v0_basicCells.lib \
              $PDK/giolib045_v3.5/timing/pads_SS_s1vg.lib

read_verilog $SYN/_UART_TOP_syn_final.v
set_top_module _UART_TOP
read_sdc $SYN/_UART_TOP_syn_final.sdc

# best-case / worst-case analysis : setup with max lib, hold with min lib
set_analysis_mode -analysisType bcwc

check_timing                                        > ./report/00_check_timing.rpt
# (pre-layout) no parasitics yet : report_annotated_parasitics is skipped
report_analysis_coverage                            > ./report/01_analysis_coverage.rpt ; # Determine violated spots are all 0

# Deal with DataCheckSetup and DataCheckHold :: Constant is skipped
report_analysis_coverage -check_type data_setup -verbose untested -exclude_untested const > ./report/02_coverage_untested.rpt

# worst paths : setup (late) and hold (early)
report_timing -late  -max_paths 10                  > ./report/03_timing_setup.rpt
report_timing -early -max_paths 10                  > ./report/04_timing_hold.rpt

##################
#### FILE OUT ####
##################
write_sdf _UART_TOP_pre_sta.sdf
exit
