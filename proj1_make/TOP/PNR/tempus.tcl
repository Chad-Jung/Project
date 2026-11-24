##########################################################
# Post-Layout STA (Vol.2 ch10) - Practice 0
# Run in PNR folder :  tempus -files tempus.tcl -log tempus.log
# RouteDesign.dat already holds the extracted RC (saveDesign -rc)
##########################################################

#### SET UP ####
read_design RouteDesign.dat _UART_TOP

file mkdir reports/sta

# 1. constraints / timing graph sanity
check_timing > reports/sta/01_check_timing.rpt

# 2. RC (parasitics) annotation coverage
report_annotated_parasitics > reports/sta/02_annotated_parasitics.rpt

# 3. timing check coverage
report_analysis_coverage > reports/sta/03_analysis_coverage.rpt
report_analysis_coverage -check_type data_setup -verbose untested -exclude_untested const > reports/sta/03_analysis_coverage_untested.rpt

# 4. worst paths : setup (FUNC_SS_WORST) / hold (FUNC_FF_BEST)
report_timing -late  -max_paths 10 > reports/sta/04_setup.rpt
report_timing -early -max_paths 10 > reports/sta/05_hold.rpt

#### FILE OUT ####
write_sdf -view FUNC_SS_WORST _UART_TOP_post_wst.sdf
write_sdf -view FUNC_FF_BEST  _UART_TOP_post_bst.sdf

##exit
