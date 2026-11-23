`timescale 1ns / 1ps

// ======================================================================
// _SYNC_FIFO_8x8 : 8-depth x 8-bit synchronous FIFO (single clock)
//   - write ignored when full  (o_overrun pulses for 1 clk)
//   - read  ignored when empty
//   - o_data is registered : valid on the clock AFTER an accepted read
// ======================================================================
module _SYNC_FIFO_8x8 (
    clr_n           ,   // async reset, active low
    clk             ,   // system clock
    i_wr            ,   // push request
    i_rd            ,   // pop request
    i_data          ,   // push data
    o_data          ,   // pop data (registered)
    o_full          ,   // FIFO full
    o_empty         ,   // FIFO empty
    o_count         ,   // number of stored entries (0 ~ 8)
    o_overrun           // push attempted while full (1-clk pulse)
);

input           clr_n       ;
input           clk         ;
input           i_wr        ;
input           i_rd        ;
input   [7:0]   i_data      ;
output  [7:0]   o_data      ;
output          o_full      ;
output          o_empty     ;
output  [3:0]   o_count     ;
output          o_overrun   ;

reg     [7:0]   o_data      ;
reg             o_overrun   ;

localparam  DEPTH   = 8 ;
localparam  AW      = 3 ;

reg     [7:0]   mem [0:DEPTH-1] ;
reg     [AW:0]  wr_ptr          ;   // MSB = wrap bit
reg     [AW:0]  rd_ptr          ;   // MSB = wrap bit

assign  o_empty = ( wr_ptr == rd_ptr ) ;
assign  o_full  = ( wr_ptr[AW] != rd_ptr[AW] ) && ( wr_ptr[AW-1:0] == rd_ptr[AW-1:0] ) ;
assign  o_count = wr_ptr - rd_ptr ;

wire            push    = i_wr & ~o_full    ;
wire            pop     = i_rd & ~o_empty   ;

// ----------------------------------------------------------------------
// write side
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )  wr_ptr <= {(AW+1){1'b0}}  ;
    else if ( push )    wr_ptr <= wr_ptr + 1'b1    ;
end

always @(posedge clk)
begin
    if ( push )         mem[wr_ptr[AW-1:0]] <= i_data ;
end

// ----------------------------------------------------------------------
// read side
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )  rd_ptr <= {(AW+1){1'b0}}  ;
    else if ( pop )     rd_ptr <= rd_ptr + 1'b1    ;
end

always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )  o_data <= 8'h00                 ;
    else if ( pop )     o_data <= mem[rd_ptr[AW-1:0]]   ;
end

// ----------------------------------------------------------------------
// overrun pulse : push requested while full
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )  o_overrun <= 1'b0           ;
    else                o_overrun <= i_wr & o_full  ;
end

endmodule
