'timescale 1ns / 1ps

module sync_fifo (
	// port list
	rst_n		, // clock signal
	clk		, // active high(positive) rest
	i_wr_en		, // active write signal
	i_wdata		, // input 8-bit data
	o_full		, // fifo is full
	i_rd_en		, // active read signal
	o_rdata		, // output 8-bit data
	o_empty		  // fifo is empty
);

// port declaration and IO diresction
input		rst_n		;
input		clk		;
input		i_wr_en		;
input	[7:0]	i_wdata		;
output		o_full		;
input		i_rd_en		;
output	[7:0]	o_rdata		;
output		o_empty		;

// 
