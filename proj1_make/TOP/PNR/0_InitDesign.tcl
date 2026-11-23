
########################################
# InitDesign (Setup, Floorplan)
# UART IP block (_UART_TOP) : hierarchical block, pins only (no IO cells)
########################################

## SDC for PnR (Vol.2 ch2.3.2) : remove set_ideal_network from the synthesis SDC
##   clock / reset buffering is done by CTS in the Back-End
##   (set_dont_touch is not used in this design)
exec grep -v set_ideal_network ../SYN/mapped/_UART_TOP_syn_final.sdc > _UART_TOP_pnr.sdc

## Initialization
set init_gnd_net VSS
set init_lef_file {../../../../SoC/GPDK045/digital/gsclib045_all_v4.4/gsclib045_tech/lef/gsclib045_tech.lef ../../../../SoC/GPDK045/digital/gsclib045_all_v4.4/gsclib045/lef/gsclib045_macro.lef ../../../../SoC/GPDK045/digital/gsclib045_all_v4.4/gsclib045/lef/gsclib045_multibitsDFF.lef}
set init_verilog ../SYN/mapped/_UART_TOP_syn_final.v
set init_mmmc_file _UART_TOP.mmmc.view
set init_top_cell _UART_TOP
set init_pwr_net VDD
init_design

## Sub-module rule (Vol.2 ch3 Hierarchical Design) : use Metal1 ~ Metal4 only
setDesignMode -topRoutingLayer Metal4 -bottomRoutingLayer Metal1

## Check Design
checkDesign -io -netlist -physicalLibrary -powerGround -tieHilo -timingLibrary -spef -floorplan -place -outdir checkDesign

##################################################
## Floorplan :: core utilization 70%, aspect ratio 1
##   cell area 2,279 um2 / 0.7 -> core about 57 x 57 um
##   10 um core-to-die margin for the power ring
##################################################
floorPlan -site CoreSite -r 1 0.7 10 10 10 10

## Pin assignment (instead of init.io IO cells)
##   left/right edge : horizontal metal (Metal3), top/bottom edge : vertical metal (Metal4)
setPinAssignMode -pinEditInBatch true
editPin -side Left   -layer 3 -spreadType center -spacing 2 -unit MICRON -fixedPin 1 -pin {i_addr[3] i_addr[2] i_addr[1] i_addr[0] i_wdata[7] i_wdata[6] i_wdata[5] i_wdata[4] i_wdata[3] i_wdata[2] i_wdata[1] i_wdata[0] i_wr i_rd}
editPin -side Right  -layer 3 -spreadType center -spacing 2 -unit MICRON -fixedPin 1 -pin {o_rdata[7] o_rdata[6] o_rdata[5] o_rdata[4] o_rdata[3] o_rdata[2] o_rdata[1] o_rdata[0] o_intr}
editPin -side Top    -layer 4 -spreadType center -spacing 4 -unit MICRON -fixedPin 1 -pin {clk clr_n}
editPin -side Bottom -layer 4 -spreadType center -spacing 4 -unit MICRON -fixedPin 1 -pin {i_rxd o_txd}
setPinAssignMode -pinEditInBatch false

# Verify Timing
report_analysis_views 
timeDesign -prePlace

## If there is no error, Save Design
saveDesign -def InitDesign
##exit
