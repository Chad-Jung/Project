`timescale 1ns / 1ps

module sync_fifo (
    // port list
    clr_n           ,   // active low(negative) reset
    clk             ,   // clock signal
    i_wr            ,   // write enable (push request)
    i_rd            ,   // read enable (pop request)
    i_data          ,   // 8-bit write data input
    o_data          ,   // 8-bit read data output
    o_full          ,   // FIFO full flag
    o_empty         ,   // FIFO empty flag
    o_count         ,   // current data count in FIFO (0 ~ DEPTH)
    o_overrun           // overrun flag : write attempted while full (data lost)
);

// port declaration and IO direction
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

// type overriding
reg     [7:0]   o_data      ;
reg             o_overrun   ;

// local parametders for FIFO geometry
localparam DEPTH = 8   ;   // FIFO depth (8-depth as per spec)
localparam AW    = 3   ;   // address width : log2(DEPTH)

// FIFO memory array (8 x 8-bit)
reg     [7:0]   mem [0:DEPTH-1] ;

// pointer registers : MSB is the wrap(toggle) bit used for full/empty decision
reg     [AW:0]  wr_ptr      ;
reg     [AW:0]  rd_ptr      ;

// address slices (drop the wrap bit)
wire    [AW-1:0]    wr_addr = wr_ptr[AW-1:0]  ;
wire    [AW-1:0]    rd_addr = rd_ptr[AW-1:0]  ;

// internal write/read qualifier (blocks write on full, read on empty)
wire            wr_en       = i_wr & ~o_full  ;
wire            rd_en       = i_rd & ~o_empty ;

// ----------------------------------------------------------------------
// Full / Empty flag logic (combinational)
// full  : wrap bits differ but addresses match (write pointer has lapped read pointer)
// empty : pointers fully identical (write pointer has not passed read pointer)
// ----------------------------------------------------------------------
assign  o_full  = ( wr_ptr[AW] != rd_ptr[AW] ) && ( wr_addr == rd_addr ) ;
assign  o_empty = ( wr_ptr == rd_ptr ) ;
assign  o_count = wr_ptr - rd_ptr ;    // occupied entry count (0 ~ DEPTH)

// ----------------------------------------------------------------------
// Process 1 : write pointer register (sequential)
// Advances on accepted write, async reset to 0
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )     wr_ptr  <= {(AW+1){1'b0}}  ; // active low | async reset to 0
    else if ( wr_en  )     wr_ptr  <= wr_ptr + 1'b1   ; // move to next write slot
end

// ----------------------------------------------------------------------
// Process 2 : read pointer register (sequential)
// Advances on accepted read, async reset to 0
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )     rd_ptr  <= {(AW+1){1'b0}}  ; // active low | async reset to 0
    else if ( rd_en  )     rd_ptr  <= rd_ptr + 1'b1   ; // move to next read slot
end

// ----------------------------------------------------------------------
// Process 3 : FIFO memory write (sequential)
// Writes i_data into mem[] at wr_addr when a write is accepted
// ----------------------------------------------------------------------
always @(posedge clk)
begin
    if ( wr_en )    mem[wr_addr]    <= i_data  ; // push data into FIFO
end

// ----------------------------------------------------------------------
// Process 4 : FIFO data output register (sequential)
// Latches mem[rd_addr] into o_data when a read is accepted
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )     o_data  <= 8'b0000_0000 ; // active low | async reset to 0
    else if ( rd_en  )     o_data  <= mem[rd_addr]  ; // pop data out of FIFO
end

// ----------------------------------------------------------------------
// Process 5 : overrun flag (sequential)
// Sets for one cycle when a write is requested while the FIFO is full
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)
begin
    if      ( ~clr_n )             o_overrun   <= 1'b0    ; // active low | async reset
    else if ( i_wr & o_full )      o_overrun   <= 1'b1    ; // write requested while full -> data lost
    else                            o_overrun   <= 1'b0    ; // pulse for one cycle only
end

endmodule
