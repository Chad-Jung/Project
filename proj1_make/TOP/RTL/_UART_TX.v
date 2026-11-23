`timescale 1ns / 1ps

module _UART_TX #(
    parameter   OSR = 16        // oversample ticks per bit period (spec : 16x)
)(
    // port list
    clr_n           ,   // active low(negative) reset
    clk             ,   // clock signal
    i_osr_tick       ,   // 16x oversample tick (from baud generator)
    i_fifo_empty     ,   // TX FIFO empty flag
    i_fifo_data      ,   // TX FIFO read data (byte to transmit)
    o_fifo_rd        ,   // TX FIFO read (pop) request
    o_txd            ,   // UART serial transmit output
    o_tx_busy            // transmitter busy flag (shifting out a frame)
);

// port declaration and IO direction
input           clr_n       ;
input           clk         ;
input           i_osr_tick  ;
input           i_fifo_empty;
input   [7:0]   i_fifo_data ;
output          o_fifo_rd   ;
output          o_txd       ;
output          o_tx_busy   ;

// type overriding
reg             o_fifo_rd   ;
reg             o_txd       ;

// local parameters for FSM states
localparam  S_IDLE  = 2'b00 ;   // line idle (mark=1), waiting for data
localparam  S_START = 2'b01 ;   // driving start bit (0)
localparam  S_DATA  = 2'b10 ;   // shifting out 8 data bits, LSB first
localparam  S_STOP  = 2'b11 ;   // driving stop bit (1)

// FSM state registers : state(current) / next_state(combinational)
reg     [1:0]   state       ;
reg     [1:0]   next_state  ;

// bit-period (oversample tick) counter and data-bit counter
reg     [3:0]   osr_cnt     ;   // counts 0 ~ (OSR-1) oversample ticks per bit
reg     [2:0]   bit_cnt     ;   // counts data bit 0 ~ 7

// tx shift register
reg     [7:0]   tx_shift    ;

// bit_done : pulses for 1 clk when the current bit period has fully elapsed
wire            bit_done    = i_osr_tick & ( osr_cnt == (OSR-1) )  ;
assign          o_tx_busy   = ( state != S_IDLE )                   ;

// ----------------------------------------------------------------------
// Process 1 : FSM state register (sequential)
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n ) state <= S_IDLE     ; // active low | async reset to idle
    else                state <= next_state; // move to the evaluated next state
end

// ----------------------------------------------------------------------
// Process 2 : next-state logic (combinational)
// ----------------------------------------------------------------------
always @(*)
begin
    next_state = state ;   // default : stay in current state
    case ( state )
        S_IDLE  : next_state = ( ~i_fifo_empty )                ? S_START : S_IDLE ;
        S_START : next_state = ( bit_done )                     ? S_DATA  : S_START;
        S_DATA  : next_state = ( bit_done & (bit_cnt == 3'd7) ) ? S_STOP  : S_DATA ;
        S_STOP  : next_state = ( bit_done )                     ? S_IDLE  : S_STOP ;
        default : next_state = S_IDLE ;
    endcase
end

// ----------------------------------------------------------------------
// Process 3 : oversample bit-period counter (sequential)
// Counts OSR ticks per bit, clears on bit_done or on any state change
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )                              osr_cnt <= 4'd0            ; // active low | async reset
    else if ( bit_done || (state != next_state) )    osr_cnt <= 4'd0            ; // restart counting for the next bit
    else if ( i_osr_tick && (state != S_IDLE) )       osr_cnt <= osr_cnt + 1'b1  ; // advance on each oversample tick
end

// ----------------------------------------------------------------------
// Process 4 : data-bit counter (sequential)
// Counts which data bit (0~7) is currently on the line during S_DATA
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )              bit_cnt <= 3'd0             ; // active low | async reset
    else if ( state != S_DATA )     bit_cnt <= 3'd0             ; // clear outside the data phase
    else if ( bit_done )             bit_cnt <= bit_cnt + 1'b1   ; // move to next data bit
end

// ----------------------------------------------------------------------
// Process 5 : tx shift register (sequential)
// Continuously latches the FIFO byte while in S_START (FIFO data is
// stable for the whole start-bit period), then shifts right, LSB first,
// once per bit during S_DATA
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )                           tx_shift <= 8'h00                   ; // active low | async reset
    else if ( state == S_START )                  tx_shift <= i_fifo_data             ; // latch byte to send
    else if ( (state == S_DATA) && bit_done )      tx_shift <= { 1'b0, tx_shift[7:1] } ; // shift right, LSB first
end

// ----------------------------------------------------------------------
// Process 6 : txd output register (sequential)
// Drives the serial line according to the current FSM state
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )     o_txd <= 1'b1          ; // active low | async reset : line idle (mark)
    else
        case ( state )
            S_IDLE  : o_txd <= 1'b1            ; // mark level
            S_START : o_txd <= 1'b0            ; // start bit
            S_DATA  : o_txd <= tx_shift[0]     ; // current LSB data bit
            S_STOP  : o_txd <= 1'b1            ; // stop bit
            default : o_txd <= 1'b1            ; // keep current value on exception
        endcase
end

// ----------------------------------------------------------------------
// Process 7 : TX FIFO read-pulse generation (sequential)
// Issues a single-cycle pop request the cycle a new byte is needed
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )                               o_fifo_rd <= 1'b0 ; // active low | async reset
    else if ( (state == S_IDLE) && (~i_fifo_empty) )  o_fifo_rd <= 1'b1 ; // pop the next byte
    else                                               o_fifo_rd <= 1'b0 ; // pulse for 1 cycle only
end

endmodule
