##########################################################
# Layout snapshot of one saved PnR stage (portfolio)
#   bash snap_all.sh                      : every stage
#   SNAP_STAGE=PlaceOpt innovus -files snap.tcl   (bash) : one stage
# Output : reports/snap/<n>_<stage>.gif  (layout canvas only, no title bar)
##########################################################
set stage $env(SNAP_STAGE)
set idx   [dict get {InitDesign 1 PowerPlan 2 PlaceOpt 3 PostCTSopt 4 RouteDesign 5 ChipFinish 6} $stage]
file mkdir reports/snap

restoreDesign ${stage}.dat _UART_TOP
fit
dumpToGIF reports/snap/${idx}_${stage}.gif

# extra views
if {$stage == "PlaceOpt"} {
    # placement density map
    setDrawView place
    setLayerPreference densityMap -isVisible 1
    fit
    dumpToGIF reports/snap/${idx}_${stage}_density.gif
    setLayerPreference densityMap -isVisible 0
}
if {$stage == "PostCTSopt"} {
    # clock nets highlighted
    deselectAll
    foreach n [dbGet [dbGet -p top.nets.isClock 1].name] { catch {selectNet $n} }
    fit
    dumpToGIF reports/snap/${idx}_${stage}_clock.gif
    deselectAll
}
exit
