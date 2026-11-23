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
    // TX line monitor (like cmsdk_uart_capture) : decodes o_txd frames
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
        input   [255:0] name;
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
        wait_tx_idle;
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
        $display("--- T7 : baud mismatch, back-to-back frames (+3%% / -3%%)");
        for ( i = 0; i < 8; i = i + 1 ) ext_send(pattern[i+8], BIT_NS*0.97, 1'b1);
        #(BIT_NS*2);
        for ( i = 0; i < 8; i = i + 1 ) begin
            reg_read(ADDR_RX_DATA, rbyte); check("+3% RX byte", rbyte, pattern[i+8]);
        end
        reg_read(ADDR_STATUS, status);  check("STATUS after +3%", status, 8'h05);

        for ( i = 0; i < 8; i = i + 1 ) ext_send(pattern[i], BIT_NS*1.03, 1'b1);
        #(BIT_NS*2);
        for ( i = 0; i < 8; i = i + 1 ) begin
            reg_read(ADDR_RX_DATA, rbyte); check("-3% RX byte", rbyte, pattern[i]);
        end
        reg_read(ADDR_STATUS, status);  check("STATUS after -3%", status, 8'h05);

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
        $display("==========================================================");
        if ( errors == 0 ) $display(" TEST PASSED");
        else               $display(" TEST FAILED : %0d error(s)", errors);
        $display("==========================================================");
        $finish;
    end

    // watchdog
    initial begin
        #(BIT_NS*1000);
        $display("[%0t] [FAIL] watchdog timeout", $time);
        $finish;
    end

endmodule
