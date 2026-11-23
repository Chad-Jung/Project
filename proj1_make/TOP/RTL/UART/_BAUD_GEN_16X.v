`timescale 1ns / 1ps

// ======================================================================
// _BAUD_GEN_16X : oversampling tick generator
//   DIVISOR = CLK_FREQ / (BAUD_RATE * OSR)     (integer division, spec 9)
//   o_osr_tick : 1-clk pulse every DIVISOR clocks (BAUD_RATE x OSR)
//   ex) 50MHz, 115200, 16 -> DIVISOR = 27 -> 115,740.7 bps (+0.47%)
// ======================================================================
module _BAUD_GEN_16X #(
    parameter   CLK_FREQ    = 50_000_000    ,   // system clock frequency (Hz)
    parameter   BAUD_RATE   = 115_200       ,   // target baud rate (bps)
    parameter   OSR         = 16                // oversampling ratio
)(
    clr_n           ,   // async reset, active low
    clk             ,   // system clock
    o_osr_tick          // oversample tick (1-clk pulse)
);

input           clr_n       ;
input           clk         ;
output          o_osr_tick  ;

reg             o_osr_tick  ;

// ----------------------------------------------------------------------
// divider geometry
// ----------------------------------------------------------------------
localparam  DIVISOR = CLK_FREQ / ( BAUD_RATE * OSR )    ;
localparam  CW      = cw(DIVISOR)                        ;

// bits needed to count 0 ~ (n-1), minimum 1
function integer cw;
    input integer n;
    integer v;
    begin
        cw = 1;
        for ( v = 2; v < n; v = v * 2 ) cw = cw + 1;
    end
endfunction

reg     [CW-1:0]    div_cnt     ;
wire                div_last    = ( div_cnt == DIVISOR - 1 ) ;

// ----------------------------------------------------------------------
// divider counter : 0 -> DIVISOR-1 -> 0 ...
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )      div_cnt <= {CW{1'b0}}       ;
    else if ( div_last )    div_cnt <= {CW{1'b0}}       ;
    else                    div_cnt <= div_cnt + 1'b1   ;
end

// ----------------------------------------------------------------------
// registered tick : one clock wide, once per DIVISOR clocks
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )      o_osr_tick <= 1'b0      ;
    else                    o_osr_tick <= div_last  ;
end

endmodule
