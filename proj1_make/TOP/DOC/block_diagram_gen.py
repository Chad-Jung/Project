# generates block_diagram.html (inline SVG)
W,H=1720,1110
o=[]
def box(x,y,w,h,inst,mod,sub,fill):
    o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="{fill}" stroke="#1a1a1a" stroke-width="2.5"/>')
    o.append(f'<text x="{x+w/2}" y="{y+h/2-14}" class="inst">{inst}</text>')
    o.append(f'<text x="{x+w/2}" y="{y+h/2+10}" class="mod">{mod}</text>')
    for i,s in enumerate(sub): o.append(f'<text x="{x+w/2}" y="{y+h/2+32+i*18}" class="sub">{s}</text>')
def arrow(pts,label=None,lx=None,ly=None,anchor="middle",bus=False,color="#1a1a1a"):
    d="M"+" L".join(f"{x},{y}" for x,y in pts)
    sw=4 if bus else 2
    o.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{sw}" marker-end="url(#ah)"/>')
    if label: o.append(f'<text x="{lx}" y="{ly}" class="sig" text-anchor="{anchor}">{label}</text>')
# top boundary
o.append('<rect x="170" y="70" width="1270" height="680" fill="none" stroke="#555" stroke-width="2" stroke-dasharray="10 6"/>')
o.append('<text x="185" y="96" class="top">_UART_TOP</text>')
# blocks
box(260,150,260,500,"U5_REG_IF","_UART_REG_IF",["Register R/W","Read MUX","INT_EN / sticky err","Interrupt OR"],"#dbe9ff")
box(690,150,240,160,"U1_TX_FIFO","_SYNC_FIFO_8x8",["8-depth x 8-bit"],"#e3f6e3")
box(690,490,240,160,"U3_RX_FIFO","_SYNC_FIFO_8x8",["8-depth x 8-bit"],"#e3f6e3")
box(1140,150,240,160,"U2_UART_TX","_UART_TX",["TX FSM, LSB first"],"#ffe9d6")
box(1140,490,240,160,"U4_UART_RX","_UART_RX",["16x mid-bit sampling","2-flop synchronizer"],"#ffe9d6")
box(1140,355,240,90,"U0_BAUD_GEN","_BAUD_GEN_16X",[],"#f3e6ff")
# REG_IF <-> TX FIFO
arrow([(520,185),(688,185)],"tx_push",604,178)
arrow([(520,220),(688,220)],"tx_wdata[7:0]",604,213,bus=True)
arrow([(690,262),(522,262)],"tx_fifo_full",604,255)
arrow([(690,292),(522,292)],"tx_fifo_empty",604,285)
# TX FIFO <-> UART_TX
arrow([(930,190),(1138,190)],"tx_fifo_rdata[7:0]",1035,183,bus=True)
arrow([(930,228),(1138,228)],"tx_fifo_empty",1035,221)
arrow([(1140,280),(932,280)],"tx_fifo_rd",1035,273)
# tx_busy back to REG_IF (over the top)
arrow([(1300,150),(1300,115),(470,115),(470,148)],"tx_busy",860,108)
# baud tick
arrow([(1260,355),(1260,312)],"osr_tick",1268,338,anchor="start")
arrow([(1260,445),(1260,488)],"osr_tick",1268,472,anchor="start")
# UART_RX <-> RX FIFO
arrow([(1140,525),(932,525)],"rx_fifo_wr",1035,518)
arrow([(1140,560),(932,560)],"rx_fifo_wdata[7:0]",1035,553,bus=True)
arrow([(930,620),(1138,620)],"rx_fifo_full",1035,613)
# RX FIFO <-> REG_IF
arrow([(520,525),(688,525)],"rx_pop",604,518)
arrow([(690,560),(522,560)],"rx_fifo_rdata[7:0]",604,553,bus=True)
arrow([(690,598),(522,598)],"rx_fifo_full",604,591)
arrow([(690,630),(522,630)],"rx_fifo_empty",604,623)
# errors (under)
arrow([(1200,650),(1200,700),(450,700),(450,652)],"frame_err",800,693)
arrow([(1320,650),(1320,725),(360,725),(360,652)],"overrun_err",800,718)
# pins right
arrow([(1380,230),(1500,230)]); o.append('<text x="1510" y="236" class="pin">o_txd</text>')
arrow([(1500,570),(1382,570)]); o.append('<text x="1510" y="576" class="pin">i_rxd</text>')
# pins left
ins=[("clk",180),("clr_n",215),("i_addr[3:0]",300),("i_wdata[7:0]",340),("i_wr",380),("i_rd",420)]
for n,y in ins:
    arrow([(90,y),(258,y)],None,bus="[" in n)
    o.append(f'<text x="84" y="{y+5}" class="pin" text-anchor="end">{n}</text>')
outs=[("o_rdata[7:0]",520),("o_intr",580)]
for n,y in outs:
    arrow([(260,y),(92,y)],None,bus="[" in n)
    o.append(f'<text x="84" y="{y+5}" class="pin" text-anchor="end">{n}</text>')
o.append('<text x="185" y="742" class="note">* clk, clr_n are connected to every block (U0~U5)</text>')
# spec tables
def table(x,y,title,rows,cw):
    o.append(f'<text x="{x}" y="{y}" class="ttitle">{title}</text>')
    yy=y+14
    for i,r in enumerate(rows):
        h=26
        fill="#e8e8e8" if i==0 else "#ffffff"
        cx=x
        for j,c in enumerate(r):
            o.append(f'<rect x="{cx}" y="{yy}" width="{cw[j]}" height="{h}" fill="{fill}" stroke="#555" stroke-width="1"/>')
            o.append(f'<text x="{cx+8}" y="{yy+18}" class="{"th" if i==0 else "td"}">{c}</text>')
            cx+=cw[j]
        yy+=h
table(90,800,"Specification (UART IP Spec Rev 1.0)",[
 ("Item","Value"),
 ("Data / Frame","8-bit, Start 1 + Data 8 + Stop 1, no parity (LSB first)"),
 ("Baud rate","115,200 bps (parameter BAUD_RATE)"),
 ("System clock","50 MHz target (parameter CLK_FREQ), synthesis 16 ns"),
 ("Oversampling","16x (OSR), RX mid-bit sampling"),
 ("FIFO","8-depth x 8-bit synchronous, TX 1 / RX 1"),
 ("Interrupt","TX empty | RX full | frame error | overrun (masked by INT_EN)"),
 ("Reset","clr_n asynchronous, active low"),
],[180,520])
table(860,800,"Register map (_UART_REG_IF)",[
 ("Addr","Name","R/W","Description"),
 ("0x0","TX_DATA","W","push 1 byte to TX FIFO (ignored if full)"),
 ("0x1","RX_DATA","R","pop 1 byte from RX FIFO (ignored if empty)"),
 ("0x2","STATUS","R","[6]tx_busy [5]overrun [4]frame_err [3]rx_full"),
 ("","","","[2]rx_empty [1]tx_full [0]tx_empty"),
 ("0x3","INT_EN","R/W","[0]tx_empty [1]rx_full [2]frame_err [3]overrun"),
 ("0x4","INT_CLR","W","write-1-to-clear : [0]frame_err [1]overrun"),
],[60,100,55,435])
svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
<defs><marker id="ah" viewBox="0 0 10 10" refX="9" refY="5" markerUnits="userSpaceOnUse" markerWidth="12" markerHeight="12" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#1a1a1a"/></marker>
<style>
text{{font-family:"DejaVu Sans",Arial,sans-serif;fill:#111}}
.inst{{font-size:20px;font-weight:bold;text-anchor:middle}}
.mod{{font-size:15px;text-anchor:middle;fill:#333}}
.sub{{font-size:13px;text-anchor:middle;fill:#444}}
.sig{{font-size:13px;fill:#0b3d91}}
.pin{{font-size:15px;font-weight:bold}}
.top{{font-size:18px;font-weight:bold;fill:#555}}
.note{{font-size:13px;fill:#555;font-style:italic}}
.note2{{font-size:12px;fill:#777}}
.ttitle{{font-size:17px;font-weight:bold}}
.th{{font-size:13px;font-weight:bold}}
.td{{font-size:13px}}
</style></defs>
<rect width="100%" height="100%" fill="#ffffff"/>
<text x="{W/2}" y="40" style="font-size:26px;font-weight:bold;text-anchor:middle">UART IP Block Diagram</text>
<g transform="translate(70,0)">{"".join(o)}</g>
</svg>'''
open('block_diagram.svg','w').write(svg)
open('block_diagram.html','w').write(f'<!doctype html><html><body style="margin:0;background:#fff">{svg}</body></html>')
