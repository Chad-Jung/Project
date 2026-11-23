`timescale 1ns / 1ps

// ======================================================================
// _UART_RX : 16x oversampled receiver  (spec 7.2, 10)
//
//   S_IDLE  : wait for rxd falling edge         rxd = 0           -> S_START
//   S_START : re-check start bit at mid-bit     mid-bit rxd = 1   -> S_IDLE (noise)
//                                               16 ticks          -> S_DATA
//   S_DATA  : sample 8 bits at mid-bit          8 bits sampled    -> S_STOP
//   S_STOP  : check stop bit at mid-bit         16 ticks          -> S_IDLE
//             and, at that moment, push the byte to the RX FIFO or raise
//             an error pulse :
//               stop = 0                 -> o_frame_err   (byte discarded)
//               stop = 1, RX FIFO full   -> o_overrun_err (byte lost)
//               stop = 1                 -> o_fifo_wr
//
//   mid-bit sampling point : tick count == OSR/2 - 1  (7 for OSR = 16)
//   rxd is synchronized with a 2-flop synchronizer.
// ======================================================================
module _UART_RX #(
    parameter   OSR = 16            // oversample ticks per bit
)(
    clr_n           ,   // async reset, active low
    clk             ,   // system clock
    i_osr_tick      ,   // oversample tick from _BAUD_GEN_16X
    i_rxd           ,   // serial input (asynchronous)
    i_fifo_full     ,   // RX FIFO full
    o_fifo_wr       ,   // RX FIFO push (1-clk pulse)
    o_fifo_data     ,   // received byte
    o_frame_err     ,   // framing error (1-clk pulse)
    o_overrun_err       // overrun error (1-clk pulse)
);

input           clr_n           ;
input           clk             ;
input           i_osr_tick      ;
input           i_rxd           ;
input           i_fifo_full     ;
output          o_fifo_wr       ;
output  [7:0]   o_fifo_data     ;
output          o_frame_err     ;
output          o_overrun_err   ;

reg             o_fifo_wr       ;
reg             o_frame_err     ;
reg             o_overrun_err   ;

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

reg             rxd_meta    ;
reg             rxd_s       ;   // synchronized rxd

reg     [1:0]       state       ;
reg     [1:0]       next_state  ;
reg     [TW-1:0]    tick_cnt    ;
reg     [2:0]       bit_cnt     ;
reg     [7:0]       shift       ;
reg                 stop_ok     ;   // stop bit value sampled at mid-bit

wire    mid_bit     = i_osr_tick & ( tick_cnt == OSR/2 - 1 ) ;
wire    bit_end     = i_osr_tick & ( tick_cnt == OSR   - 1 ) ;

assign  o_fifo_data = shift ;

// ----------------------------------------------------------------------
// 2-flop synchronizer (reset to the idle/mark level)
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if ( ~clr_n )   { rxd_s, rxd_meta } <= 2'b11              ;
    else            { rxd_s, rxd_meta } <= { rxd_meta, i_rxd } ;
end

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
        S_IDLE  : if ( ~rxd_s )                         next_state = S_START ;
        S_START : if ( mid_bit & rxd_s )                next_state = S_IDLE  ;   // false start
                  else if ( bit_end )                   next_state = S_DATA  ;
        S_DATA  : if ( bit_end && ( bit_cnt == 3'd7 ) ) next_state = S_STOP  ;
        S_STOP  : if ( bit_end )                        next_state = S_IDLE  ;
        default :                                       next_state = S_IDLE  ;
    endcase
end

// ----------------------------------------------------------------------
// bit timing : tick count restarts on the falling edge and every bit
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
// data sampling : shift in at MSB, LSB arrives first
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )                              shift <= 8'h00                  ;
    else if ( state == S_DATA && mid_bit )          shift <= { rxd_s, shift[7:1] }  ;
end

always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )                              stop_ok <= 1'b0     ;
    else if ( state == S_STOP && mid_bit )          stop_ok <= rxd_s    ;
end

// ----------------------------------------------------------------------
// end of stop bit : push / error pulses (1 clk)
// ----------------------------------------------------------------------
wire    frame_done  = ( state == S_STOP ) & bit_end ;

always @(posedge clk or negedge clr_n)
begin
    if ( ~clr_n ) begin
        o_fifo_wr       <= 1'b0 ;
        o_frame_err     <= 1'b0 ;
        o_overrun_err   <= 1'b0 ;
    end
    else begin
        o_fifo_wr       <= frame_done &  stop_ok & ~i_fifo_full ;
        o_frame_err     <= frame_done & ~stop_ok                ;
        o_overrun_err   <= frame_done &  stop_ok &  i_fifo_full ;
    end
end

endmodule
