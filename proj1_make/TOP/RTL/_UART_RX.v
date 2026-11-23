`timescale 1ns / 1ps

module _UART_RX #(
    parameter   OSR = 16        // oversample ticks per bit period (spec : 16x)
)(
    // port list
    clr_n           ,   // active low(negative) reset
    clk             ,   // clock signal
    i_osr_tick       ,   // 16x oversample tick (from baud generator)
    i_rxd            ,   // UART serial receive input (async)
    i_fifo_full      ,   // RX FIFO full flag (for overrun detection)
    o_fifo_wr        ,   // RX FIFO write (push) request
    o_fifo_data      ,   // RX FIFO write data (received byte)
    o_frame_err      ,   // framing error pulse (stop bit was not seen as 1)
    o_overrun_err        // overrun error pulse (byte received while RX FIFO full)
);

// port declaration and IO direction
input           clr_n       ;
input           clk         ;
input           i_osr_tick  ;
input           i_rxd       ;
input           i_fifo_full ;
output          o_fifo_wr   ;
output  [7:0]   o_fifo_data ;
output          o_frame_err ;
output          o_overrun_err;

// type overriding
reg             o_fifo_wr   ;
reg     [7:0]   o_fifo_data ;
reg             o_frame_err ;
reg             o_overrun_err;

// local parameters for FSM states
localparam  S_IDLE  = 2'b00 ;   // line idle, watching for a start edge
localparam  S_START = 2'b01 ;   // validating the start bit (mid-bit check)
localparam  S_DATA  = 2'b10 ;   // sampling 8 data bits, LSB first
localparam  S_STOP  = 2'b11 ;   // validating the stop bit

// 2-flop synchronizer for the asynchronous serial input
reg             rxd_meta    ;
reg             rxd_sync    ;

// FSM state registers : state(current) / next_state(combinational)
reg     [1:0]   state       ;
reg     [1:0]   next_state  ;

// oversample bit-period counter and data-bit counter
reg     [3:0]   osr_cnt     ;   // counts 0 ~ (OSR-1) oversample ticks per bit
reg     [2:0]   bit_cnt     ;   // counts data bit 0 ~ 7

// rx shift register
reg     [7:0]   rx_shift    ;

// mid_tick : pulses at the middle of the bit period (sampling point)
// bit_done : pulses at the end   of the bit period
wire            mid_tick    = i_osr_tick & ( osr_cnt == (OSR/2 - 1) ) ;
wire            bit_done    = i_osr_tick & ( osr_cnt == (OSR-1)     ) ;

// ----------------------------------------------------------------------
// Process 1 : input synchronizer (sequential)
// 2-flop synchronizer to resolve metastability on the async rxd input
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )     { rxd_sync, rxd_meta } <= 2'b11                ; // active low | async reset : idle mark level
    else                    { rxd_sync, rxd_meta } <= { rxd_meta, i_rxd } ; // shift the async input through 2 flops
end

// ----------------------------------------------------------------------
// Process 2 : FSM state register (sequential)
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n ) state <= S_IDLE     ; // active low | async reset to idle
    else                state <= next_state; // move to the evaluated next state
end

// ----------------------------------------------------------------------
// Process 3 : next-state logic (combinational)
// ----------------------------------------------------------------------
always @(*)
begin
    next_state = state ;   // default : stay in current state
    case ( state )
        S_IDLE : begin
            if      ( ~rxd_sync )              next_state = S_START   ; // falling edge -> possible start bit
            else                                 next_state = S_IDLE    ;
        end
        S_START : begin
            if      ( mid_tick & rxd_sync )     next_state = S_IDLE    ; // glitch/noise -> not a real start bit
            else if ( bit_done )                 next_state = S_DATA    ; // confirmed start bit -> begin data phase
            else                                  next_state = S_START   ;
        end
        S_DATA : begin
            if      ( bit_done & (bit_cnt == 3'd7) ) next_state = S_STOP ; // all 8 data bits received
            else                                        next_state = S_DATA ;
        end
        S_STOP : begin
            if      ( bit_done )                 next_state = S_IDLE    ; // stop bit period elapsed -> back to idle
            else                                   next_state = S_STOP    ;
        end
        default : next_state = S_IDLE ;
    endcase
end

// ----------------------------------------------------------------------
// Process 4 : oversample bit-period counter (sequential)
// Counts OSR ticks per bit, clears on bit_done or on any state change
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )                              osr_cnt <= 4'd0            ; // active low | async reset
    else if ( bit_done || (state != next_state) )    osr_cnt <= 4'd0            ; // restart counting for the next bit
    else if ( i_osr_tick && (state != S_IDLE) )       osr_cnt <= osr_cnt + 1'b1  ; // advance on each oversample tick
end

// ----------------------------------------------------------------------
// Process 5 : data-bit counter (sequential)
// Counts which data bit (0~7) is currently being sampled during S_DATA
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )              bit_cnt <= 3'd0             ; // active low | async reset
    else if ( state != S_DATA )     bit_cnt <= 3'd0             ; // clear outside the data phase
    else if ( bit_done )             bit_cnt <= bit_cnt + 1'b1   ; // move to next data bit
end

// ----------------------------------------------------------------------
// Process 6 : rx shift register (sequential)
// Samples rxd_sync at the middle of each data bit, shifts in at MSB;
// after 8 samples bit[0] holds the first-received (LSB) data bit
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )                           rx_shift <= 8'h00                     ; // active low | async reset
    else if ( (state == S_DATA) && mid_tick )      rx_shift <= { rxd_sync, rx_shift[7:1] } ; // sample at mid-bit
end

// ----------------------------------------------------------------------
// Process 7 : stop-bit check, RX FIFO push, framing/overrun error flags
// (sequential, evaluated once at the middle of the stop-bit period)
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if ( ~clr_n ) begin
        o_fifo_wr       <= 1'b0    ; // active low | async reset
        o_fifo_data      <= 8'h00   ;
        o_frame_err      <= 1'b0    ;
        o_overrun_err     <= 1'b0    ;
    end
    else if ( (state == S_STOP) && mid_tick ) begin
        if ( rxd_sync ) begin                          // valid stop bit (1)
            o_frame_err <= 1'b0 ;
            if ( i_fifo_full ) begin
                o_fifo_wr      <= 1'b0 ;                // RX FIFO full -> drop data
                o_overrun_err   <= 1'b1 ;
            end
            else begin
                o_fifo_wr      <= 1'b1 ;                // push received byte
                o_fifo_data     <= rx_shift ;
                o_overrun_err    <= 1'b0 ;
            end
        end
        else begin                                      // invalid stop bit (0) -> framing error
            o_frame_err      <= 1'b1 ;
            o_fifo_wr         <= 1'b0 ;                 // discard malformed frame
            o_overrun_err      <= 1'b0 ;
        end
    end
    else begin
        o_fifo_wr       <= 1'b0 ;  // pulse for 1 cycle only
        o_frame_err      <= 1'b0 ;  // pulse for 1 cycle only
        o_overrun_err     <= 1'b0 ;  // pulse for 1 cycle only
    end
end

endmodule
