`timescale 1ns / 1ps

module _BAUD_GEN_16X #(
    parameter   CLK_FREQ    = 50_000_000  ,   // system clock frequency (Hz)
    parameter   BAUD_RATE   = 115_200     ,   // target baud rate (bps)
    parameter   OSR         = 16              // oversampling ratio (spec : 16x)
)(
    // port list
    clr_n           ,   // active low(negative) reset
    clk             ,   // clock signal
    o_osr_tick           // 1-clock pulse at 16x oversampling rate (BAUD_RATE * OSR)
);

// port declaration and IO direction
input           clr_n       ;
input           clk         ;
output          o_osr_tick  ;

// type overriding
reg             o_osr_tick  ;

// local parameters for the divider
localparam  DIVISOR = CLK_FREQ / ( BAUD_RATE * OSR )   ;   // clk cycles per oversample tick
localparam  CW       = 16                               ;   // counter width (wide enough for any practical DIVISOR)

// divider counter
reg     [CW-1:0]   div_cnt     ;

// ----------------------------------------------------------------------
// Process 1 : divider counter (sequential)
// Counts system clock cycles, wraps every DIVISOR cycles
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )                          div_cnt <= {CW{1'b0}}     ; // active low | async reset to 0
    else if ( div_cnt == (DIVISOR - 1) )        div_cnt <= {CW{1'b0}}     ; // wrap at DIVISOR
    else                                         div_cnt <= div_cnt + 1'b1; // count up
end

// ----------------------------------------------------------------------
// Process 2 : oversample tick register (sequential)
// Pulses one clk cycle each time the divider wraps (16x baud rate)
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )                          o_osr_tick <= 1'b0        ; // active low | async reset
    else if ( div_cnt == (DIVISOR - 1) )        o_osr_tick <= 1'b1        ; // generate 1-cycle tick
    else                                         o_osr_tick <= 1'b0        ; // hold low otherwise
end

endmodule
