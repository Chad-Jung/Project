`timescale 1ns / 1ps

// ======================================================================
// _UART_TX : Start(0) - Data(8, LSB first) - Stop(1) transmitter  (spec 7.1)
//
//   S_IDLE  : txd = 1                  FIFO not empty  -> S_START (pop)
//   S_START : txd = 0                  16 osr ticks    -> S_DATA  (load)
//   S_DATA  : txd = shift[0]           8 bits sent     -> S_STOP
//   S_STOP  : txd = 1                  16 osr ticks    -> S_IDLE
//
//   The FIFO pop is issued in S_IDLE; the FIFO's registered output is
//   stable for the whole start bit and is loaded into the shifter at the
//   end of S_START.
// ======================================================================
module _UART_TX #(
    parameter   OSR = 16            // oversample ticks per bit
)(
    clr_n           ,   // async reset, active low
    clk             ,   // system clock
    i_osr_tick      ,   // oversample tick from _BAUD_GEN_16X
    i_fifo_empty    ,   // TX FIFO empty
    i_fifo_data     ,   // TX FIFO read data (registered in the FIFO)
    o_fifo_rd       ,   // TX FIFO pop request
    o_txd           ,   // serial output
    o_tx_busy           // frame in progress
);

input           clr_n       ;
input           clk         ;
input           i_osr_tick  ;
input           i_fifo_empty;
input   [7:0]   i_fifo_data ;
output          o_fifo_rd   ;
output          o_txd       ;
output          o_tx_busy   ;

reg             o_txd       ;

localparam  S_IDLE  = 2'd0 ;
localparam  S_START = 2'd1 ;
localparam  S_DATA  = 2'd2 ;
localparam  S_STOP  = 2'd3 ;

localparam  TW      = cw(OSR) ;

// bits needed to count 0 ~ (n-1), minimum 1
function integer cw;
    input integer n;
    integer v;
    begin
        cw = 1;
        for ( v = 2; v < n; v = v * 2 ) cw = cw + 1;
    end
endfunction

reg     [1:0]       state       ;
reg     [1:0]       next_state  ;
reg     [TW-1:0]    tick_cnt    ;   // oversample ticks within the current bit
reg     [2:0]       bit_cnt     ;   // data bit index 0 ~ 7
reg     [7:0]       shift       ;

wire    bit_end     = i_osr_tick & ( tick_cnt == OSR - 1 ) ;

assign  o_fifo_rd   = ( state == S_IDLE ) & ~i_fifo_empty ;
assign  o_tx_busy   = ( state != S_IDLE ) ;

// ----------------------------------------------------------------------
// FSM
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if ( ~clr_n )   state <= S_IDLE     ;
    else            state <= next_state ;
end

always @(*)
begin
    next_state = state;
    case ( state )
        S_IDLE  : if ( ~i_fifo_empty )                  next_state = S_START ;
        S_START : if ( bit_end )                        next_state = S_DATA  ;
        S_DATA  : if ( bit_end && ( bit_cnt == 3'd7 ) ) next_state = S_STOP  ;
        S_STOP  : if ( bit_end )                        next_state = S_IDLE  ;
        default :                                       next_state = S_IDLE  ;
    endcase
end

// ----------------------------------------------------------------------
// bit timing : counts oversample ticks, restarts at every bit boundary
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )                              tick_cnt <= {TW{1'b0}}      ;
    else if ( state == S_IDLE || bit_end )          tick_cnt <= {TW{1'b0}}      ;
    else if ( i_osr_tick )                          tick_cnt <= tick_cnt + 1'b1 ;
end

always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )                              bit_cnt <= 3'd0             ;
    else if ( state != S_DATA )                     bit_cnt <= 3'd0             ;
    else if ( bit_end )                             bit_cnt <= bit_cnt + 1'b1   ;
end

// ----------------------------------------------------------------------
// shift register : load at end of start bit, shift right after each data bit
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )                              shift <= 8'h00                  ;
    else if ( state == S_START && bit_end )         shift <= i_fifo_data            ;
    else if ( state == S_DATA  && bit_end )         shift <= { 1'b0, shift[7:1] }   ;
end

// ----------------------------------------------------------------------
// registered serial output (glitch-free)
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if ( ~clr_n )   o_txd <= 1'b1;
    else
        case ( next_state )
            S_START :   o_txd <= 1'b0       ;
            S_DATA  :   o_txd <= ( state == S_START ) ? i_fifo_data[0] :
                                 ( bit_end )          ? shift[1]       : shift[0] ;
            default :   o_txd <= 1'b1       ;   // S_IDLE, S_STOP
        endcase
end

endmodule
