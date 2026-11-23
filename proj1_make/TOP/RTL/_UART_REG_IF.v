`timescale 1ns / 1ps

// ======================================================================
// _UART_REG_IF : generic register R/W interface + interrupt  (spec 8, 10)
//
//   addr  name     R/W  description
//   0x0   TX_DATA  W    push 1 byte into TX FIFO (ignored when full)
//   0x1   RX_DATA  R    pop 1 byte from RX FIFO  (ignored when empty)
//   0x2   STATUS   R    [7] reserved   [6] tx_busy   [5] overrun_err (sticky)
//                       [4] frame_err (sticky)       [3] rx_full
//                       [2] rx_empty   [1] tx_full   [0] tx_empty
//   0x3   INT_EN   R/W  [0] tx_empty_en [1] rx_full_en [2] frame_err_en
//                       [3] overrun_err_en
//   0x4   INT_CLR  W    write-1-to-clear : [0] frame_err_s  [1] overrun_err_s
//
//   o_intr = (INT_EN[0] & tx_empty)    | (INT_EN[1] & rx_full) |
//            (INT_EN[2] & frame_err_s) | (INT_EN[3] & overrun_err_s)
//
//   Bus timing
//     write : i_wr / i_addr / i_wdata sampled on the rising edge
//     read  : i_rd / i_addr sampled on the rising edge; o_rdata is valid
//             during the next cycle (RX_DATA comes from the FIFO's
//             registered output, other registers are combinational)
// ======================================================================
module _UART_REG_IF (
    clr_n           ,   // async reset, active low
    clk             ,   // system clock
    i_addr          ,   // register address
    i_wdata         ,   // write data
    i_wr            ,   // write strobe
    i_rd            ,   // read strobe
    o_rdata         ,   // read data
    o_tx_push       ,   // TX FIFO push
    o_tx_wdata      ,   // TX FIFO push data
    o_rx_pop        ,   // RX FIFO pop
    i_rx_rdata      ,   // RX FIFO pop data (registered in the FIFO)
    i_tx_full       ,   // TX FIFO full
    i_tx_empty      ,   // TX FIFO empty
    i_rx_full       ,   // RX FIFO full
    i_rx_empty      ,   // RX FIFO empty
    i_tx_busy       ,   // transmitter busy
    i_frame_err     ,   // framing error pulse from RX
    i_overrun_err   ,   // overrun error pulse from RX
    o_intr              // combined interrupt
);

input           clr_n           ;
input           clk             ;
input   [3:0]   i_addr          ;
input   [7:0]   i_wdata         ;
input           i_wr            ;
input           i_rd            ;
output  [7:0]   o_rdata         ;
output          o_tx_push       ;
output  [7:0]   o_tx_wdata      ;
output          o_rx_pop        ;
input   [7:0]   i_rx_rdata      ;
input           i_tx_full       ;
input           i_tx_empty      ;
input           i_rx_full       ;
input           i_rx_empty      ;
input           i_tx_busy       ;
input           i_frame_err     ;
input           i_overrun_err   ;
output          o_intr          ;

reg     [7:0]   o_rdata         ;

localparam  ADDR_TX_DATA    = 4'h0 ;
localparam  ADDR_RX_DATA    = 4'h1 ;
localparam  ADDR_STATUS     = 4'h2 ;
localparam  ADDR_INT_EN     = 4'h3 ;
localparam  ADDR_INT_CLR    = 4'h4 ;

reg     [3:0]   int_en          ;
reg             frame_err_s     ;
reg             overrun_err_s   ;

wire    wr_tx_data  = i_wr & ( i_addr == ADDR_TX_DATA ) ;
wire    wr_int_en   = i_wr & ( i_addr == ADDR_INT_EN  ) ;
wire    wr_int_clr  = i_wr & ( i_addr == ADDR_INT_CLR ) ;
wire    rd_rx_data  = i_rd & ( i_addr == ADDR_RX_DATA ) ;

// ----------------------------------------------------------------------
// FIFO access (full / empty requests are ignored)
// ----------------------------------------------------------------------
assign  o_tx_push   = wr_tx_data & ~i_tx_full   ;
assign  o_tx_wdata  = i_wdata                   ;
assign  o_rx_pop    = rd_rx_data & ~i_rx_empty  ;

// ----------------------------------------------------------------------
// INT_EN register
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )      int_en <= 4'b0000       ;
    else if ( wr_int_en )   int_en <= i_wdata[3:0]  ;
end

// ----------------------------------------------------------------------
// sticky error flags : set by RX pulse, cleared by W1C (set wins)
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )                      frame_err_s <= 1'b0 ;
    else if ( i_frame_err )                 frame_err_s <= 1'b1 ;
    else if ( wr_int_clr & i_wdata[0] )     frame_err_s <= 1'b0 ;
end

always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )                      overrun_err_s <= 1'b0 ;
    else if ( i_overrun_err )               overrun_err_s <= 1'b1 ;
    else if ( wr_int_clr & i_wdata[1] )     overrun_err_s <= 1'b0 ;
end

// ----------------------------------------------------------------------
// read mux
// ----------------------------------------------------------------------
always @(*)
begin
    case ( i_addr )
        ADDR_RX_DATA :  o_rdata = i_rx_rdata ;
        ADDR_STATUS  :  o_rdata = { 1'b0, i_tx_busy, overrun_err_s, frame_err_s,
                                    i_rx_full, i_rx_empty, i_tx_full, i_tx_empty } ;
        ADDR_INT_EN  :  o_rdata = { 4'b0000, int_en } ;
        default      :  o_rdata = 8'h00 ;     // TX_DATA / INT_CLR are write-only
    endcase
end

// ----------------------------------------------------------------------
// combined interrupt
// ----------------------------------------------------------------------
assign  o_intr  = ( int_en[0] & i_tx_empty    ) |
                  ( int_en[1] & i_rx_full     ) |
                  ( int_en[2] & frame_err_s   ) |
                  ( int_en[3] & overrun_err_s ) ;

endmodule
