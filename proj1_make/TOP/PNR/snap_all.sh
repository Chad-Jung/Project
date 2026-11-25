#!/bin/bash
# Take layout snapshots of every saved PnR stage, one Innovus session per stage
# usage (in PNR folder) : bash snap_all.sh
for s in InitDesign PowerPlan PlaceOpt PostCTSopt RouteDesign ChipFinish; do
    echo "=== snapshot : $s"
    SNAP_STAGE=$s innovus -files snap.tcl -log snap_$s.log
done
ls -l reports/snap
