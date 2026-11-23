`timescale 1ns / 1ps

// ======================================================================
// tb_UART_TOP : self-checking testbench for _UART_TOP
//
// Common testbench for every simulation stage (TESTBENCH folder):
//   - Function Simulation   : +define+function_sim   (RTL, no delay)
//   - Pre/Post-layout Sim.  : +define+sdf_gate       (gate netlist + SDF)
//
// Clock : design target 50MHz (20ns). Simulated pessimistically 30% faster
//         -> 14ns period, same policy as the course (10ns target -> 7ns sim).
//         The DUT is instantiated with its DEFAULT parameters so the same
//         testbench can be reused on the synthesized netlist unchanged.
//
// STATUS register (addr 0x2) bit map
//   [6] tx_busy [5] overrun_err [4] frame_err [3] rx_full
//   [2] rx_empty [1] tx_full    [0] tx_empty
// ======================================================================
module tb_UART_TOP;

    // ------------------------------------------------------------------
    // parameters (must match _UART_TOP defaults)
    // ------------------------------------------------------------------
    parameter   CLK_FREQ    = 50_000_000    ;
    parameter   BAUD_RATE   = 115_200       ;
    parameter   OSR         = 16            ;
    parameter   CLK_PERIOD  = 14            ;   // ns, pessimistic (target 20ns)

    localparam  DIVISOR     = CLK_FREQ / ( BAUD_RATE * OSR )    ;
    localparam  BIT_NS      = OSR * DIVISOR * CLK_PERIOD        ;   // one UART bit time in this sim

    // register map
    localparam  ADDR_TX_DATA = 4'h0 ;
    localparam  ADDR_RX_DATA = 4'h1 ;
    localparam  ADDR_STATUS  = 4'h2 ;
    localparam  ADDR_INT_EN  = 4'h3 ;
    localparam  ADDR_INT_CLR = 4'h4 ;

    // ------------------------------------------------------------------
    // DUT signals
    // ------------------------------------------------------------------
    reg             clr_n   ;
    reg             clk     ;
    reg     [3:0]   addr    ;
    reg     [7:0]   wdata   ;
    reg             wr      ;
    reg             rd      ;
    wire    [7:0]   rdata   ;
    wire            intr    ;
    wire            txd     ;
    wire            rxd     ;

    reg             loopback;   // 1 : txd -> rxd , 0 : external serial model drives rxd
    reg             ext_rxd ;

    assign  rxd = loopback ? txd : ext_rxd ;

    integer         errors  ;
    integer         i       ;
    reg     [7:0]   rbyte   ;
    reg     [7:0]   status  ;
    reg     [7:0]   pattern [0:15] ;
    real            t_edge, t_now  ;

    // ------------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------------
    _UART_TOP DUT (
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

    // ------------------------------------------------------------------
    // clock / reset
    // ------------------------------------------------------------------
    initial clk = 1'b0;
    always  #(CLK_PERIOD/2.0) clk = ~clk;

    // ------------------------------------------------------------------
    // waveform dump / SDF annotation
    // ------------------------------------------------------------------
    initial begin
`ifdef __ICARUS__
        $dumpfile("dump/tb_UART_TOP.vcd");
        $dumpvars(0, tb_UART_TOP);
`else
  `ifdef function_sim
        $shm_open("dump/function_sim.shm");
        $shm_probe("AS");
  `endif
  `ifdef sdf_gate
        $sdf_annotate("../../SYN/mapped/_UART_TOP_delays.sdf", DUT, , "sdf.log", "MAXIMUM");
        $shm_open("dump/gate_sim.shm");
        $shm_probe("AS");
  `endif
`endif
    end

    // ------------------------------------------------------------------
    // TX line monitor : decodes o_txd frames
    // ------------------------------------------------------------------
    reg     [7:0]   mon_byte    ;
    reg     [7:0]   mon_buf [0:63] ;
    integer         mon_cnt     ;
    integer         b           ;

    initial begin
        mon_cnt = 0;
        forever begin
            @(negedge txd);
            if ( clr_n ) begin
                #(BIT_NS/2);                            // middle of start bit
                if ( txd !== 1'b0 )
                    $display("[%0t] [MON ] glitch on txd (not a start bit)", $time);
                else begin
                    for ( b = 0; b < 8; b = b + 1 ) begin
                        #(BIT_NS);
                        mon_byte[b] = txd;               // LSB first
                    end
                    #(BIT_NS);                          // middle of stop bit
                    if ( txd !== 1'b1 )
                        $display("[%0t] [MON ] TX framing error, byte 0x%02h", $time, mon_byte);
                    mon_buf[mon_cnt % 64] = mon_byte;
                    mon_cnt = mon_cnt + 1;
                end
            end
        end
    end

    // ------------------------------------------------------------------
    // register access tasks (inputs change 1ns after the rising edge)
    // ------------------------------------------------------------------
    task reg_write;
        input   [3:0]   a;
        input   [7:0]   d;
        begin
            @(posedge clk); #1;
            addr = a; wdata = d; wr = 1'b1;
            @(posedge clk); #1;
            wr   = 1'b0;
        end
    endtask

    task reg_read;
        input   [3:0]   a;
        output  [7:0]   d;
        begin
            @(posedge clk); #1;
            addr = a; rd = 1'b1;
            @(posedge clk); #1;                         // RX FIFO o_data updates on this edge
            d    = rdata;
            rd   = 1'b0;
        end
    endtask

    task check;
        input   [8*48-1:0] name;   // up to 48 characters
        input   [7:0]   got;
        input   [7:0]   exp;
        begin
            if ( got !== exp ) begin
                $display("[%0t] [FAIL] %0s : got 0x%02h, expected 0x%02h", $time, name, got, exp);
                errors = errors + 1;
            end
            else
                $display("[%0t] [PASS] %0s : 0x%02h", $time, name, got);
        end
    endtask

    // wait until the transmitter has drained the TX FIFO and the shifter
    task wait_tx_idle;
        begin
            status = 8'h00;
            while ( !(status[0] && !status[6]) ) reg_read(ADDR_STATUS, status);
            #(BIT_NS*2);                                // last frame reaches RX stop bit
        end
    endtask

    // external serial transmitter model (drives ext_rxd)
    //   bit_ns : bit time  (use != BIT_NS to model baud mismatch)
    //   stop   : stop bit value (0 -> framing error)
    task ext_send;
        input   [7:0]   d;
        input   real    bit_ns;
        input           stop;
        integer         k;
        begin
            ext_rxd = 1'b0;             #(bit_ns);      // start
            for ( k = 0; k < 8; k = k + 1 ) begin
                ext_rxd = d[k];         #(bit_ns);      // data, LSB first
            end
            ext_rxd = stop;             #(bit_ns);      // stop
            ext_rxd = 1'b1;
        end
    endtask

    // ------------------------------------------------------------------
    // test sequence
    // ------------------------------------------------------------------
    initial begin
        errors   = 0;
        loopback = 1'b1;
        ext_rxd  = 1'b1;
        clr_n    = 1'b0;
        addr     = 4'h0; wdata = 8'h00; wr = 1'b0; rd = 1'b0;

        for ( i = 0; i < 16; i = i + 1 ) pattern[i] = 8'h11 * i ^ 8'hA5;

        $display("==========================================================");
        $display(" tb_UART_TOP : CLK %0dns, DIVISOR %0d, bit time %0dns", CLK_PERIOD, DIVISOR, BIT_NS);
        $display("==========================================================");

        repeat (5) @(posedge clk);
        #1 clr_n = 1'b1;
        repeat (5) @(posedge clk);

        // --------------------------------------------------------------
        $display("--- T1 : reset values");
        reg_read(ADDR_STATUS, status);  check("STATUS after reset", status, 8'h05);
        reg_read(ADDR_INT_EN, rbyte);   check("INT_EN after reset", rbyte,  8'h00);
        check("txd idle level", {7'd0, txd}, 8'h01);
        check("intr after reset", {7'd0, intr}, 8'h00);

        // --------------------------------------------------------------
        $display("--- T2 : single byte loopback");
        reg_write(ADDR_TX_DATA, 8'h5A);
        wait_tx_idle;
        reg_read(ADDR_STATUS, status);  check("STATUS rx_empty=0", status & 8'h04, 8'h00);
        reg_read(ADDR_RX_DATA, rbyte);  check("RX byte", rbyte, 8'h5A);
        check("TX monitor byte", mon_buf[0], 8'h5A);
        reg_read(ADDR_STATUS, status);  check("STATUS back to empty", status, 8'h05);

        // --------------------------------------------------------------
        $display("--- T3 : 8-byte burst (FIFO depth) loopback");
        for ( i = 0; i < 8; i = i + 1 ) reg_write(ADDR_TX_DATA, pattern[i]);
        wait_tx_idle;
        reg_read(ADDR_STATUS, status);  check("STATUS rx_full", status & 8'h08, 8'h08);
        for ( i = 0; i < 8; i = i + 1 ) begin
            reg_read(ADDR_RX_DATA, rbyte); check("burst RX byte", rbyte, pattern[i]);
        end
        reg_read(ADDR_STATUS, status);  check("STATUS empty again", status, 8'h05);

        // --------------------------------------------------------------
        $display("--- T4 : TX FIFO full + RX overrun");
        reg_write(ADDR_INT_EN, 8'b0000_1000);           // overrun interrupt only
        for ( i = 0; i < 10; i = i + 1 ) reg_write(ADDR_TX_DATA, pattern[i]);
        // 1 byte in the shifter + 8 in the FIFO -> full, 10th write is dropped
        reg_read(ADDR_STATUS, status);  check("STATUS tx_full", status & 8'h02, 8'h02);
        i = mon_cnt;
        wait_tx_idle;
        check("frames sent (10th write ignored)", mon_cnt - i, 8'd9);
        // 9 frames sent, RX FIFO holds 8 -> 9th is an overrun
        reg_read(ADDR_STATUS, status);  check("STATUS rx_full+overrun", status & 8'h28, 8'h28);
        check("intr (overrun)", {7'd0, intr}, 8'h01);
        for ( i = 0; i < 8; i = i + 1 ) begin
            reg_read(ADDR_RX_DATA, rbyte); check("overrun RX byte", rbyte, pattern[i]);
        end
        reg_write(ADDR_INT_CLR, 8'b0000_0010);          // W1C overrun
        reg_read(ADDR_STATUS, status);  check("STATUS overrun cleared", status, 8'h05);
        check("intr cleared", {7'd0, intr}, 8'h00);

        // --------------------------------------------------------------
        $display("--- T5 : framing error (stop bit = 0)");
        loopback = 1'b0;
        reg_write(ADDR_INT_EN, 8'b0000_0100);           // frame error interrupt only
        ext_send(8'hC3, BIT_NS, 1'b0);
        #(BIT_NS*2);
        reg_read(ADDR_STATUS, status);  check("STATUS frame_err, no data", status & 8'h14, 8'h14);
        check("intr (frame err)", {7'd0, intr}, 8'h01);
        reg_write(ADDR_INT_CLR, 8'b0000_0001);          // W1C frame error
        reg_read(ADDR_STATUS, status);  check("STATUS frame_err cleared", status, 8'h05);

        // --------------------------------------------------------------
        $display("--- T6 : false start (glitch shorter than half a bit)");
        ext_rxd = 1'b0; #(BIT_NS/4); ext_rxd = 1'b1;
        #(BIT_NS*12);
        reg_read(ADDR_STATUS, status);  check("STATUS no byte, no error", status, 8'h05);

        // --------------------------------------------------------------
        // external transmitter at the nominal bit time, no idle gap between frames
        // (baud-mismatch tests removed : spec 7.2 S_STOP waits the full 16 ticks)
        $display("--- T7 : external serial input, 8 back-to-back frames");
        for ( i = 0; i < 8; i = i + 1 ) ext_send(pattern[i+8], BIT_NS, 1'b1);
        #(BIT_NS*2);
        for ( i = 0; i < 8; i = i + 1 ) begin
            reg_read(ADDR_RX_DATA, rbyte); check("external RX byte", rbyte, pattern[i+8]);
        end
        reg_read(ADDR_STATUS, status);  check("STATUS after external RX", status, 8'h05);

        // --------------------------------------------------------------
        $display("--- T8 : TX empty interrupt");
        loopback = 1'b1;
        reg_write(ADDR_INT_EN, 8'b0000_0001);
        check("intr (tx empty)", {7'd0, intr}, 8'h01);
        // 1st byte moves straight into the shifter, 2nd byte stays in the FIFO
        reg_write(ADDR_TX_DATA, 8'h3C);
        reg_write(ADDR_TX_DATA, 8'hC3);
        repeat (2) @(posedge clk); #1;
        check("intr low while TX FIFO not empty", {7'd0, intr}, 8'h00);
        wait_tx_idle;
        check("intr (tx empty again)", {7'd0, intr}, 8'h01);
        reg_read(ADDR_RX_DATA, rbyte);  check("RX byte 1", rbyte, 8'h3C);
        reg_read(ADDR_RX_DATA, rbyte);  check("RX byte 2", rbyte, 8'hC3);
        reg_write(ADDR_INT_EN, 8'h00);

        // --------------------------------------------------------------
        // spec 9 : DIVISOR = 27 -> 1 bit = 16 ticks = 432 clk
        // spec 7.1 : start / data / stop bits are 16 osr ticks each
        //   0x55 = 0101_0101 -> every data bit toggles the line
        $display("--- T9 : TX bit timing (spec 7.1 / 9)");
        reg_write(ADDR_TX_DATA, 8'h55);
        @(negedge txd);  t_edge = $realtime;            // start bit begins
        @(posedge txd);  t_now  = $realtime;            // D0 (=1) begins
        // start bit : 16 ticks counted from the FSM entering S_START; the
        // first tick may come 1..DIVISOR clocks later (free-running baud gen)
        if ( (t_now - t_edge) > BIT_NS || (t_now - t_edge) <= BIT_NS - DIVISOR*CLK_PERIOD ) begin
            $display("[%0t] [FAIL] start bit width %0.0f ns", $time, t_now - t_edge);
            errors = errors + 1;
        end
        else $display("[%0t] [PASS] start bit width %0.0f ns (15~16 ticks)", $time, t_now - t_edge);
        for ( i = 1; i < 8; i = i + 1 ) begin           // D1 .. D7 edges
            t_edge = t_now;
            @(txd);  t_now = $realtime;
            if ( t_now - t_edge != BIT_NS ) begin
                $display("[%0t] [FAIL] data bit width %0.0f ns, expected %0d", $time, t_now - t_edge, BIT_NS);
                errors = errors + 1;
            end
        end
        t_edge = t_now;                                 // D7 (=0) begins
        @(posedge txd);  t_now = $realtime;             // stop bit begins
        if ( t_now - t_edge != BIT_NS ) begin
            $display("[%0t] [FAIL] D7 width %0.0f ns", $time, t_now - t_edge);
            errors = errors + 1;
        end
        else $display("[%0t] [PASS] data bit width = %0d ns (16 x %0d clk)", $time, BIT_NS, DIVISOR);
        t_edge = t_now;
        wait ( DUT.tx_busy == 1'b0 );  t_now = $realtime;
        if ( (t_now - t_edge) < BIT_NS - CLK_PERIOD || (t_now - t_edge) > BIT_NS + CLK_PERIOD ) begin
            $display("[%0t] [FAIL] stop bit width %0.0f ns", $time, t_now - t_edge);
            errors = errors + 1;
        end
        else $display("[%0t] [PASS] stop bit width %0.0f ns", $time, t_now - t_edge);
        #(BIT_NS);
        reg_read(ADDR_RX_DATA, rbyte);  check("RX byte", rbyte, 8'h55);

        // --------------------------------------------------------------
        $display("--- T10 : register map details (spec 8)");
        // RX_DATA read while empty is ignored (no pointer change)
        reg_read(ADDR_RX_DATA, rbyte);
        reg_read(ADDR_STATUS, status);  check("RX_DATA read when empty -> still empty", status, 8'h05);
        check("RX FIFO count after empty read", {4'd0, DUT.U3_RX_FIFO.o_count}, 8'd0);
        // INT_EN : only [3:0] are implemented
        reg_write(ADDR_INT_EN, 8'hFA);
        reg_read(ADDR_INT_EN, rbyte);   check("INT_EN readback [3:0] only", rbyte, 8'h0A);
        reg_write(ADDR_INT_EN, 8'h00);
        // write-only / undefined addresses read as 0
        reg_read(ADDR_TX_DATA, rbyte);  check("TX_DATA reads 0", rbyte, 8'h00);
        reg_read(ADDR_INT_CLR, rbyte);  check("INT_CLR reads 0", rbyte, 8'h00);
        reg_read(4'hF, rbyte);          check("undefined addr reads 0", rbyte, 8'h00);
        // writes to read-only / undefined addresses have no effect
        reg_write(ADDR_STATUS, 8'hFF);
        reg_write(4'hF, 8'hFF);
        reg_read(ADDR_STATUS, status);  check("STATUS unchanged by writes", status, 8'h05);
        reg_read(ADDR_INT_EN, rbyte);   check("INT_EN unchanged by other writes", rbyte, 8'h00);

        // --------------------------------------------------------------
        $display("--- T11 : interrupt sources and W1C (spec 8, 10)");
        // RX full interrupt
        reg_write(ADDR_INT_EN, 8'b0000_0010);
        for ( i = 0; i < 8; i = i + 1 ) reg_write(ADDR_TX_DATA, pattern[i]);
        wait_tx_idle;
        check("intr (rx full)", {7'd0, intr}, 8'h01);
        reg_read(ADDR_RX_DATA, rbyte);
        @(posedge clk); #1;
        check("intr low after one pop", {7'd0, intr}, 8'h00);
        for ( i = 1; i < 8; i = i + 1 ) reg_read(ADDR_RX_DATA, rbyte);
        // both sticky errors set, then cleared one at a time
        loopback = 1'b0;
        ext_send(8'h00, BIT_NS, 1'b0);                  // framing error
        #(BIT_NS);
        for ( i = 0; i < 9; i = i + 1 ) ext_send(pattern[i], BIT_NS, 1'b1);   // 9th -> overrun
        #(BIT_NS*2);
        reg_read(ADDR_STATUS, status);  check("both sticky errors set", status & 8'h30, 8'h30);
        reg_write(ADDR_INT_EN, 8'b0000_1100);
        reg_write(ADDR_INT_CLR, 8'b0000_0001);          // clear frame_err only
        reg_read(ADDR_STATUS, status);  check("W1C bit0 clears frame_err only", status & 8'h30, 8'h20);
        check("intr still high (overrun)", {7'd0, intr}, 8'h01);
        reg_write(ADDR_INT_CLR, 8'b0000_0000);          // writing 0 does nothing
        reg_read(ADDR_STATUS, status);  check("W1C with 0 keeps overrun", status & 8'h30, 8'h20);
        reg_write(ADDR_INT_CLR, 8'b0000_0010);
        reg_read(ADDR_STATUS, status);  check("W1C bit1 clears overrun", status & 8'h30, 8'h00);
        check("intr low", {7'd0, intr}, 8'h00);
        for ( i = 0; i < 8; i = i + 1 ) reg_read(ADDR_RX_DATA, rbyte);
        reg_write(ADDR_INT_EN, 8'h00);
        reg_read(ADDR_STATUS, status);  check("STATUS final", status, 8'h05);

        // --------------------------------------------------------------
        $display("==========================================================");
        if ( errors == 0 ) $display(" TEST PASSED");
        else               $display(" TEST FAILED : %0d error(s)", errors);
        $display("==========================================================");
`ifdef function_sim
        $stop;                                          // GUI : stay open to inspect the waveform
`endif
        $finish;
    end

    // watchdog
    initial begin
        #(BIT_NS*1000);
        $display("[%0t] [FAIL] watchdog timeout", $time);
        $finish;
    end

endmodule
