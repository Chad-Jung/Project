# PnR Import Files (Innovus init_design)

Block-level PnR of `_UART_TOP` (no IO pad cells, pins only).  
Library files are referenced by name only; the library itself is not distributed.

| # | Category | File | Producer / origin | Innovus setting | Note |
|---|---|---|---|---|---|
| 1 | Gate netlist | `_UART_TOP_syn_final.v` | Genus synthesis (`SYN/mapped`) | `init_verilog` | hierarchical, 6 sub-modules |
| 2 | Timing constraint | `_UART_TOP_pnr.sdc` | `_UART_TOP_syn_final.sdc` minus `set_ideal_network` (made in `0_InitDesign.tcl`) | MMMC constraint mode `FUNC` | clock 16 ns, false path `i_rxd`, `clr_n` |
| 3 | MMMC view | `_UART_TOP.mmmc.view` | written for this project (course template) | `init_mmmc_file` | 2 corners, 2 views (below) |
| 4 | Tech LEF | `gsclib045_tech.lef` | GPDK045 | `init_lef_file` | layers, vias, site `CoreSite` |
| 5 | Cell LEF | `gsclib045_macro.lef`, `gsclib045_multibitsDFF.lef` | GPDK045 | `init_lef_file` | standard cell abstracts |
| 6 | Timing library (max) | `slow_vdd1v0_basicCells.lib`, `slow_vdd1v0_multibitsDFF.lib`, `pads_SS_s1vg.lib` | GPDK045 | library set `SS_Max_0p90v_125c` | PVT 0.9 V / 125 C |
| 7 | Timing library (min) | `fast_vdd1v0_basicCells.lib`, `fast_vdd1v0_multibitsDFF.lib`, `pads_FF_s1vg.lib` | GPDK045 | library set `FF_Min_1p10v_0c` | PVT 1.1 V / 0 C |
| 8 | RC model | cap table (`*.capTbl`), QRC tech (`gpdk045.tch`) | GPDK045 | RC corners `WORST` (125 C), `BEST` (0 C) | pre/post-route RC |
| 9 | Top / power | top cell `_UART_TOP`, power nets `VDD`, `VSS` | - | `init_top_cell`, `init_pwr_net`, `init_gnd_net` | |
| 10 | Pin placement | `editPin` commands in `0_InitDesign.tcl` | written for this project | (no IO file) | L/R : Metal3, T/B : Metal4 |

## MMMC configuration

| Analysis view | Constraint mode | Delay corner | Library set | RC corner | Check |
|---|---|---|---|---|---|
| `FUNC_SS_WORST` | `FUNC` | `SS_WORST` | `SS_Max_0p90v_125c` | `WORST` | setup |
| `FUNC_FF_BEST` | `FUNC` | `FF_BEST` | `FF_Min_1p10v_0c` | `BEST` | hold |

## Physical setup

| Item | Value |
|---|---|
| Routing layers | Metal1 ~ Metal4 (`setDesignMode -topRoutingLayer Metal4`) |
| Floorplan | aspect ratio 1, core utilization 70 %, core-to-die 10 um |
| Die size | 77.8 x 76.57 um |
| Power | core ring (top/bottom Metal3, left/right Metal4, width 2 um), Metal1 rails, Metal4 stripes x3 pairs (20 um pitch) |
| Pins | 27 (Metal3 23, Metal4 4) |

## Output files (Chip Finish)

| File | Used by |
|---|---|
| `_UART_TOP.v` (flat netlist) | Post-layout EC (Conformal) |
| `_UART_TOP_hier.v` (hierarchical netlist) | Post-layout simulation (matches Tempus SDF hierarchy) |
| `RouteDesign.dat` (`saveDesign -rc`) | Post-layout STA (Tempus `read_design`) |
| `_UART_TOP_post_wst.sdf`, `_UART_TOP_post_bst.sdf` (Tempus) | Post-layout simulation max / min |
| `_UART_TOP.gds`, `_UART_TOP.sdc` | GDS out / constraint out |
