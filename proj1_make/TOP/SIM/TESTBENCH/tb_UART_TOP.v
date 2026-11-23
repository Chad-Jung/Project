`timescale 1ns / 1ps

// ----------------------------------------------------------------------
// tb_UART_TOP : loopback self-check (o_txd wired back to i_rxd)
// Run locally, e.g. :
//   iverilog -o sim _SYNC_FIFO_8x8.v _BAUD_GEN_16X.v _UART_TX.v _UART_RX.v \
//            _UART_REG_IF.v _UART_TOP.v tb_UART_TOP.v
//   vvp sim
// ----------------------------------------------------------------------
module tb_UART_TOP;

    reg         clr_n   ;
    reg         clk     ;
    reg  [3:0]  addr    ;
    reg  [7:0]  wdata   ;
    reg         wr      ;
    reg         rd      ;
    wire [7:0]  rdata   ;
    wire        intr    ;
    wire        txd     ;
    reg         rxd     ;

    integer     errors  ;

    // small/fast clock+divisor for quick simulation : 1MHz clk, 16x oversample
    // divisor = 1,000,000 / (115200*16) -> use a low CLK_FREQ so DIVISOR rounds to >=1
    _UART_TOP #(
        .CLK_FREQ   ( 1_843_200 ),   // chosen so DIVISOR = 1 -> fastest possible sim
        .BAUD_RATE  ( 115_200   ),
        .OSR        ( 16        )
    ) DUT (
        .clr_n      ( clr_n ),
        .clk        ( clk   ),
        .i_addr     ( addr  ),
        .i_wdata    ( wdata ),
        .i_wr       ( wr    ),
        .i_rd       ( rd    ),
        .o_rdata    ( rdata ),
        .o_intr     ( intr  ),
        .o_txd      ( txd   ),
        .i_rxd      ( rxd   )
    );

    // loopback : TX pin directly feeds RX pin
    always @(*) rxd = txd;

    // 1,843,200 Hz clock -> period ~ 542.5 ns (approx, fine for functional sim)
    initial clk = 0;
    always #271 clk = ~clk;

    task reg_write(input [3:0] a, input [7:0] d);
        begin
            @(posedge clk);
            addr  = a; wdata = d; wr = 1'b1;
            @(posedge clk);
            wr = 1'b0;
        end
    endtask

    task reg_read(input [3:0] a, output [7:0] d);
        begin
            @(posedge clk);
            addr = a; rd = 1'b1;
            @(posedge clk);
            #1;              // BUGFIX: let this edge's nonblocking (<=) updates
                              // (e.g. the RX FIFO's registered o_data) settle in
                              // the NBA region before a blocking read samples
                              // rdata -- without this, d would race ahead and
                              // capture the pre-update (stale) value.
            d = rdata;
            rd = 1'b0;
        end
    endtask

    reg [7:0] status, rx_byte;

    initial begin
        errors = 0;
        clr_n = 0; wr = 0; rd = 0; addr = 0; wdata = 0;
        repeat (5) @(posedge clk);
        clr_n = 1;
        repeat (5) @(posedge clk);

        // enable all interrupts
        reg_write(4'h3, 8'b0000_1111);

        // push one byte (0x5A) into TX FIFO -> UART shifts it out -> loops back into RX
        reg_write(4'h0, 8'h5A);

        // wait long enough for a full 10-bit frame to be received
        // 10 bits * 16 osr ticks * divisor clk cycles, generous margin
        repeat (10 * 16 * 2 + 200) @(posedge clk);

        reg_read(4'h2, status);          // STATUS register
        if ( status[1] )                 // bit1 = rx_empty -> no byte arrived
            begin
                $display("[FAIL] RX FIFO empty - no byte received");
                errors = errors + 1;
            end
        else
            begin
                reg_read(4'h1, rx_byte); // RX_DATA
                if ( rx_byte !== 8'h5A )
                    begin
                        $display("[FAIL] RX byte mismatch : expected 0x5A, got 0x%0h", rx_byte);
                        errors = errors + 1;
                    end
                else
                    $display("[PASS] Loopback byte matched : 0x%0h", rx_byte);
            end

        if ( errors == 0 )
            $display("=== ALL CHECKS PASSED ===");
        else
            $display("=== %0d CHECK(S) FAILED ===", errors);

        $finish;
    end

endmodule
