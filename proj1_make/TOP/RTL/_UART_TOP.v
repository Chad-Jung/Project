`timescale 1ns / 1ps

// ======================================================================
// _UART_TOP : UART IP top level  (UART IP spec Rev 1.0)
//
//   CPU reg access -> _UART_REG_IF -> TX FIFO -> _UART_TX -> o_txd
//   i_rxd -> _UART_RX -> RX FIFO -> _UART_REG_IF -> CPU reg access
//
//   CLK_FREQ must be set to the real system clock of the target.
// ======================================================================
module _UART_TOP #(
    parameter   CLK_FREQ    = 50_000_000    ,   // system clock (Hz)
    parameter   BAUD_RATE   = 115_200       ,   // baud rate (bps)
    parameter   OSR         = 16                // oversampling ratio
)(
    clr_n           ,   // async reset, active low
    clk             ,   // system clock
    i_addr          ,   // register address
    i_wdata         ,   // register write data
    i_wr            ,   // register write strobe
    i_rd            ,   // register read strobe
    o_rdata         ,   // register read data
    o_intr          ,   // combined interrupt
    o_txd           ,   // UART serial TX
    i_rxd               // UART serial RX
);

input           clr_n       ;
input           clk         ;
input   [3:0]   i_addr      ;
input   [7:0]   i_wdata     ;
input           i_wr        ;
input           i_rd        ;
output  [7:0]   o_rdata     ;
output          o_intr      ;
output          o_txd       ;
input           i_rxd       ;

wire            osr_tick        ;

wire            tx_push         ;
wire    [7:0]   tx_wdata        ;
wire            tx_fifo_rd      ;
wire    [7:0]   tx_fifo_rdata   ;
wire            tx_fifo_full    ;
wire            tx_fifo_empty   ;
wire            tx_busy         ;

wire            rx_fifo_wr      ;
wire    [7:0]   rx_fifo_wdata   ;
wire            rx_pop          ;
wire    [7:0]   rx_fifo_rdata   ;
wire            rx_fifo_full    ;
wire            rx_fifo_empty   ;
wire            frame_err       ;
wire            overrun_err     ;

// ----------------------------------------------------------------------
// U0 : oversampling tick generator
// ----------------------------------------------------------------------
_BAUD_GEN_16X #(
    .CLK_FREQ       ( CLK_FREQ      ),
    .BAUD_RATE      ( BAUD_RATE     ),
    .OSR            ( OSR           )
) U0_BAUD_GEN (
    .clr_n          ( clr_n         ),
    .clk            ( clk           ),
    .o_osr_tick     ( osr_tick      )
);

// ----------------------------------------------------------------------
// U1 : TX FIFO
// ----------------------------------------------------------------------
_SYNC_FIFO_8x8 U1_TX_FIFO (
    .clr_n          ( clr_n         ),
    .clk            ( clk           ),
    .i_wr           ( tx_push       ),
    .i_rd           ( tx_fifo_rd    ),
    .i_data         ( tx_wdata      ),
    .o_data         ( tx_fifo_rdata ),
    .o_full         ( tx_fifo_full  ),
    .o_empty        ( tx_fifo_empty ),
    .o_count        (               ),
    .o_overrun      (               )
);

// ----------------------------------------------------------------------
// U2 : transmitter
// ----------------------------------------------------------------------
_UART_TX #(
    .OSR            ( OSR           )
) U2_UART_TX (
    .clr_n          ( clr_n         ),
    .clk            ( clk           ),
    .i_osr_tick     ( osr_tick      ),
    .i_fifo_empty   ( tx_fifo_empty ),
    .i_fifo_data    ( tx_fifo_rdata ),
    .o_fifo_rd      ( tx_fifo_rd    ),
    .o_txd          ( o_txd         ),
    .o_tx_busy      ( tx_busy       )
);

// ----------------------------------------------------------------------
// U3 : RX FIFO
// ----------------------------------------------------------------------
_SYNC_FIFO_8x8 U3_RX_FIFO (
    .clr_n          ( clr_n         ),
    .clk            ( clk           ),
    .i_wr           ( rx_fifo_wr    ),
    .i_rd           ( rx_pop        ),
    .i_data         ( rx_fifo_wdata ),
    .o_data         ( rx_fifo_rdata ),
    .o_full         ( rx_fifo_full  ),
    .o_empty        ( rx_fifo_empty ),
    .o_count        (               ),
    .o_overrun      (               )
);

// ----------------------------------------------------------------------
// U4 : receiver
// ----------------------------------------------------------------------
_UART_RX #(
    .OSR            ( OSR           )
) U4_UART_RX (
    .clr_n          ( clr_n         ),
    .clk            ( clk           ),
    .i_osr_tick     ( osr_tick      ),
    .i_rxd          ( i_rxd         ),
    .i_fifo_full    ( rx_fifo_full  ),
    .o_fifo_wr      ( rx_fifo_wr    ),
    .o_fifo_data    ( rx_fifo_wdata ),
    .o_frame_err    ( frame_err     ),
    .o_overrun_err  ( overrun_err   )
);

// ----------------------------------------------------------------------
// U5 : register interface
// ----------------------------------------------------------------------
_UART_REG_IF U5_REG_IF (
    .clr_n          ( clr_n         ),
    .clk            ( clk           ),
    .i_addr         ( i_addr        ),
    .i_wdata        ( i_wdata       ),
    .i_wr           ( i_wr          ),
    .i_rd           ( i_rd          ),
    .o_rdata        ( o_rdata       ),
    .o_tx_push      ( tx_push       ),
    .o_tx_wdata     ( tx_wdata      ),
    .o_rx_pop       ( rx_pop        ),
    .i_rx_rdata     ( rx_fifo_rdata ),
    .i_tx_full      ( tx_fifo_full  ),
    .i_tx_empty     ( tx_fifo_empty ),
    .i_rx_full      ( rx_fifo_full  ),
    .i_rx_empty     ( rx_fifo_empty ),
    .i_tx_busy      ( tx_busy       ),
    .i_frame_err    ( frame_err     ),
    .i_overrun_err  ( overrun_err   ),
    .o_intr         ( o_intr        )
);

endmodule
