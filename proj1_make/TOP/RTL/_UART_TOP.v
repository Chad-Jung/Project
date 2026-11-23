`timescale 1ns / 1ps

module _UART_TOP #(
    parameter   CLK_FREQ    = 50_000_000  ,   // system clock frequency (Hz) - adjust to target board
    parameter   BAUD_RATE   = 115_200     ,   // spec : 115,200 bps
    parameter   OSR         = 16              // spec : 16x oversampling clock (RX sampling)
)(
    // port list
    clr_n           ,   // active low(negative) reset
    clk             ,   // clock signal
    i_addr           ,   // generic register address
    i_wdata          ,   // generic register write data
    i_wr             ,   // generic register write strobe
    i_rd             ,   // generic register read strobe
    o_rdata          ,   // generic register read data
    o_intr           ,   // combined interrupt : TX Empty/RX Full/Frame Err/Overrun Err
    o_txd            ,   // UART serial transmit pin
    i_rxd                // UART serial receive pin
);

// port declaration and IO direction
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

// internal wires : baud generator
wire            osr_tick        ;

// internal wires : TX path
wire            tx_push         ;
wire    [7:0]   tx_wdata        ;
wire            tx_fifo_full    ;
wire            tx_fifo_empty   ;
wire    [7:0]   tx_fifo_rdata   ;
wire            tx_fifo_rd      ;
wire            tx_busy         ;

// internal wires : RX path
wire            rx_pop          ;
wire    [7:0]   rx_fifo_rdata   ;
wire            rx_fifo_full    ;
wire            rx_fifo_empty   ;
wire            rx_fifo_wr      ;
wire    [7:0]   rx_fifo_wdata   ;
wire            frame_err       ;
wire            overrun_err     ;

// ----------------------------------------------------------------------
// U0 : 16x oversampling baud rate generator
// ----------------------------------------------------------------------
_BAUD_GEN_16X #(
    .CLK_FREQ   ( CLK_FREQ      ),
    .BAUD_RATE  ( BAUD_RATE     ),
    .OSR        ( OSR           )
) U0_BAUD_GEN (
    .clr_n      ( clr_n         ),
    .clk        ( clk           ),
    .o_osr_tick ( osr_tick      )
);

// ----------------------------------------------------------------------
// U1 : TX FIFO (8-depth x 8-bit, synchronous, single clock domain)
// ----------------------------------------------------------------------
_SYNC_FIFO_8x8 U1_TX_FIFO (
    .clr_n      ( clr_n         ),
    .clk        ( clk           ),
    .i_wr       ( tx_push       ),
    .i_rd       ( tx_fifo_rd    ),
    .i_data     ( tx_wdata      ),
    .o_data     ( tx_fifo_rdata ),
    .o_full     ( tx_fifo_full  ),
    .o_empty    ( tx_fifo_empty ),
    .o_count    (               ),
    .o_overrun  (               )
);

// ----------------------------------------------------------------------
// U2 : UART transmitter (start-data-stop shifter, driven by TX FIFO)
// ----------------------------------------------------------------------
_UART_TX #(
    .OSR         ( OSR           )
) U2_UART_TX (
    .clr_n       ( clr_n         ),
    .clk         ( clk           ),
    .i_osr_tick  ( osr_tick      ),
    .i_fifo_empty( tx_fifo_empty ),
    .i_fifo_data ( tx_fifo_rdata ),
    .o_fifo_rd   ( tx_fifo_rd    ),
    .o_txd       ( o_txd         ),
    .o_tx_busy   ( tx_busy       )
);

// ----------------------------------------------------------------------
// U3 : RX FIFO (8-depth x 8-bit, synchronous, single clock domain)
// ----------------------------------------------------------------------
_SYNC_FIFO_8x8 U3_RX_FIFO (
    .clr_n      ( clr_n         ),
    .clk        ( clk           ),
    .i_wr       ( rx_fifo_wr    ),
    .i_rd       ( rx_pop        ),
    .i_data     ( rx_fifo_wdata ),
    .o_data     ( rx_fifo_rdata ),
    .o_full     ( rx_fifo_full  ),
    .o_empty    ( rx_fifo_empty ),
    .o_count    (               ),
    .o_overrun  (               )
);

// ----------------------------------------------------------------------
// U4 : UART receiver (16x oversampled start-data-stop recovery)
// ----------------------------------------------------------------------
_UART_RX #(
    .OSR           ( OSR           )
) U4_UART_RX (
    .clr_n         ( clr_n         ),
    .clk           ( clk           ),
    .i_osr_tick    ( osr_tick      ),
    .i_rxd         ( i_rxd         ),
    .i_fifo_full   ( rx_fifo_full  ),
    .o_fifo_wr     ( rx_fifo_wr    ),
    .o_fifo_data   ( rx_fifo_wdata ),
    .o_frame_err   ( frame_err     ),
    .o_overrun_err ( overrun_err   )
);

// ----------------------------------------------------------------------
// U5 : generic register R/W interface (an APB wrapper can sit on top)
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
