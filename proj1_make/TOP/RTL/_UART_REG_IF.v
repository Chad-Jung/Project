`timescale 1ns / 1ps                                                           // 시뮬레이션 시간 단위 = 1ns, 최소 분해능 = 1ps

module _UART_REG_IF (                                                         // 범용 레지스터 R/W 인터페이스 (APB 등 버스 래퍼를 얇게 씌울 수 있는 구조)
    // port list
    clr_n           ,   // active low(negative) reset                         // 0이면 리셋
    clk             ,   // clock signal                                       // 시스템 클럭
    i_addr           ,   // generic register address                         // CPU가 접근하려는 레지스터 주소
    i_wdata          ,   // generic register write data                      // CPU가 쓰려는 데이터
    i_wr             ,   // generic register write strobe                    // "지금 쓸게요" 신호
    i_rd             ,   // generic register read strobe                     // "지금 읽을게요" 신호
    o_rdata          ,   // generic register read data                       // CPU가 읽어갈 데이터
    o_tx_push        ,   // 1-cycle pulse : push o_tx_wdata into TX FIFO      // TX FIFO에 바이트를 넣으라는 1클럭 펄스
    o_tx_wdata       ,   // byte to push into TX FIFO                        // TX FIFO에 넣을 바이트
    o_rx_pop         ,   // 1-cycle pulse : pop a byte from RX FIFO           // RX FIFO에서 바이트를 꺼내라는 1클럭 펄스
    i_rx_rdata       ,   // byte already popped from RX FIFO (registered)    // RX FIFO가 이미 꺼내놓은 바이트
    i_tx_full        ,   // TX FIFO full flag                                // TX FIFO 꽉 찼는지
    i_tx_empty       ,   // TX FIFO empty flag                               // TX FIFO 비었는지
    i_rx_full        ,   // RX FIFO full flag                                // RX FIFO 꽉 찼는지
    i_rx_empty       ,   // RX FIFO empty flag                               // RX FIFO 비었는지
    i_tx_busy        ,   // UART transmitter busy flag                       // 송신기가 지금 보내는 중인지
    i_frame_err      ,   // framing error pulse from RX                      // RX에서 온 프레임 에러 펄스
    i_overrun_err    ,   // overrun error pulse from RX                      // RX에서 온 오버런 에러 펄스
    o_intr               // combined interrupt request output                // 여러 에러/상태를 하나로 합친 인터럽트 출력
);

// port declaration and IO direction
input           clr_n       ;   // 1비트 입력, 비동기 리셋
input           clk         ;   // 1비트 입력, 시스템 클럭
input   [3:0]   i_addr      ;   // 4비트 입력, 레지스터 주소 (0~15번 중 선택)
input   [7:0]   i_wdata     ;   // 8비트 입력, 쓸 데이터
input           i_wr        ;   // 1비트 입력, 쓰기 스트로브
input           i_rd        ;   // 1비트 입력, 읽기 스트로브
output  [7:0]   o_rdata     ;   // 8비트 출력, 읽은 데이터
output          o_tx_push   ;   // 1비트 출력, TX FIFO push 펄스
output  [7:0]   o_tx_wdata  ;   // 8비트 출력, TX FIFO에 넣을 바이트
output          o_rx_pop    ;   // 1비트 출력, RX FIFO pop 펄스
input   [7:0]   i_rx_rdata  ;   // 8비트 입력, RX FIFO에서 나온 바이트
input           i_tx_full   ;   // 1비트 입력, TX FIFO full
input           i_tx_empty  ;   // 1비트 입력, TX FIFO empty
input           i_rx_full   ;   // 1비트 입력, RX FIFO full
input           i_rx_empty  ;   // 1비트 입력, RX FIFO empty
input           i_tx_busy   ;   // 1비트 입력, 송신 busy
input           i_frame_err ;   // 1비트 입력, 프레임 에러
input           i_overrun_err;  // 1비트 입력, 오버런 에러
output          o_intr      ;   // 1비트 출력, 통합 인터럽트

// type overriding
reg     [7:0]   o_rdata     ;   // 조합회로(always@*)에서 대입하므로 reg로 재선언
reg             o_tx_push   ;   // always 블록에서 대입하므로 reg로 재선언
reg     [7:0]   o_tx_wdata  ;   // always 블록에서 대입하므로 reg로 재선언
// o_rx_pop은 아래에서 assign(조합회로)으로 선언하므로 reg 재선언 없음 (wire 유지)

// local parameters for the register map
localparam  ADDR_TX_DATA = 4'h0 ; // W  : write a byte  -> TX FIFO              // 0번 주소 : 쓰기 전용, 여기 쓰면 TX FIFO로 들어감
localparam  ADDR_RX_DATA = 4'h1 ; // R  : read  a byte  <- RX FIFO              // 1번 주소 : 읽기 전용, 여기 읽으면 RX FIFO에서 꺼내옴
localparam  ADDR_STATUS  = 4'h2 ; // R  : 상태 비트들을 모아놓은 레지스터        // 2번 주소 : 읽기 전용, 각종 플래그 묶음
localparam  ADDR_INT_EN  = 4'h3 ; // R/W: interrupt enable [3:0]                // 3번 주소 : 읽기/쓰기, 인터럽트 켜고 끄는 마스크
localparam  ADDR_INT_CLR = 4'h4 ; // W  : write-1-to-clear sticky error bits    // 4번 주소 : 쓰기 전용, 1을 쓰면 해당 에러 플래그를 지움

// interrupt enable register and sticky error flags
reg     [3:0]   int_en          ;   // 4개의 인터럽트 각각을 켜고 끄는 마스크 레지스터
reg             frame_err_s     ;   // sticky framing-error flag                 // 한번 에러가 나면 지울 때까지 계속 1로 남아있는 플래그
reg             overrun_err_s   ;   // sticky overrun-error flag                 // 한번 에러가 나면 지울 때까지 계속 1로 남아있는 플래그

// ----------------------------------------------------------------------
// Process 1 : TX FIFO push generation (sequential)
// Pulses one cycle when the host writes TX_DATA and the TX FIFO is not full
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)                                      // 클럭 상승엣지 또는 리셋 하강엣지에서 실행
begin
    if      ( ~clr_n )                                             o_tx_push <= 1'b0  ; // 리셋이면 0
    else if ( i_wr && (i_addr == ADDR_TX_DATA) && (~i_tx_full) )    o_tx_push <= 1'b1  ; // TX_DATA 주소에 쓰기가 들어왔고 FIFO가 안 꽉찼으면 push 요청 1클럭
    else                                                             o_tx_push <= 1'b0  ; // 그 외에는 0
end

always @(posedge clk or negedge clr_n)                                      // 클럭 상승엣지 또는 리셋 하강엣지에서 실행
begin
    if      ( ~clr_n )                                             o_tx_wdata <= 8'h00 ; // 리셋이면 0
    else if ( i_wr && (i_addr == ADDR_TX_DATA) && (~i_tx_full) )    o_tx_wdata <= i_wdata; // 같은 조건에서 실제로 보낼 바이트를 래치
end

// ----------------------------------------------------------------------
// Process 2 : RX FIFO pop generation (combinational)
// BUGFIX (found via iverilog pre-check) : this used to be a registered
// pulse (posedge clk), which added one extra cycle of latency on top of
// the RX FIFO's own registered o_data output -- so a host that waits
// only 1 cycle after asserting i_rd (the normal, expected register-read
// contract) would read stale data. Making the pop combinational lines
// the FIFO's pop request up with i_rd/i_addr in the SAME cycle, so the
// FIFO's o_data updates exactly 1 cycle later -- matching the single
// wait-cycle a host/CPU normally assumes for a register read.
// 버그 수정(iverilog 사전검증에서 발견) : 기존에는 pop 신호가 레지스터라서
// FIFO 자체 출력 레지스터 지연 위에 1클럭이 더 쌓여, 호스트가 통상적인
// "1클럭 대기 후 읽기" 규약대로 읽으면 묵은 데이터를 읽는 버그가 있었다.
// pop을 조합회로로 바꿔 i_rd/i_addr과 같은 클럭에 요청이 나가도록 하면,
// FIFO의 o_data는 정확히 1클럭 뒤에 갱신되어 호스트의 1클럭 읽기 규약과
// 맞아떨어진다.
// ----------------------------------------------------------------------
assign  o_rx_pop = i_rd && (i_addr == ADDR_RX_DATA) && (~i_rx_empty) ; // RX_DATA 주소를 읽고 FIFO가 안 비었으면 같은 클럭에 pop 요청

// ----------------------------------------------------------------------
// Process 3 : interrupt enable register (sequential)
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)                                      // 클럭 상승엣지 또는 리셋 하강엣지에서 실행
begin
    if      ( ~clr_n )                           int_en <= 4'b0000     ; // 리셋이면 전부 마스크(끔)
    else if ( i_wr && (i_addr == ADDR_INT_EN) )   int_en <= i_wdata[3:0]; // INT_EN 주소에 쓰면 그 값을 그대로 마스크 레지스터에 저장
end

// ----------------------------------------------------------------------
// Process 4 : sticky error flag registers (sequential)
// Set by RX error pulses, cleared by a write-1-to-clear to ADDR_INT_CLR
// ----------------------------------------------------------------------
always @(posedge clk or negedge clr_n)                                      // 클럭 상승엣지 또는 리셋 하강엣지에서 실행
begin
    if      ( ~clr_n )                                         frame_err_s <= 1'b0 ; // 리셋이면 0
    else if ( i_frame_err )                                     frame_err_s <= 1'b1 ; // RX에서 프레임 에러 펄스가 오면 1로 래치(계속 유지)
    else if ( i_wr && (i_addr == ADDR_INT_CLR) && i_wdata[0] )   frame_err_s <= 1'b0 ; // CPU가 INT_CLR의 0번 비트에 1을 쓰면 지움
end

always @(posedge clk or negedge clr_n)                                      // 클럭 상승엣지 또는 리셋 하강엣지에서 실행
begin
    if      ( ~clr_n )                                         overrun_err_s <= 1'b0 ; // 리셋이면 0
    else if ( i_overrun_err )                                   overrun_err_s <= 1'b1 ; // RX에서 오버런 에러 펄스가 오면 1로 래치(계속 유지)
    else if ( i_wr && (i_addr == ADDR_INT_CLR) && i_wdata[1] )   overrun_err_s <= 1'b0 ; // CPU가 INT_CLR의 1번 비트에 1을 쓰면 지움
end

// ----------------------------------------------------------------------
// Process 5 : register read mux (combinational)
// ----------------------------------------------------------------------
always @(*)                                               // i_addr이나 상태값이 바뀔 때마다 즉시 재계산되는 조합회로
begin
    case ( i_addr )                                        // 주소에 따라 어떤 값을 내보낼지 결정
        ADDR_RX_DATA : o_rdata = i_rx_rdata ;                                        // RX_DATA 주소면 받은 데이터를 그대로 내보냄
        ADDR_STATUS  : o_rdata = { 1'b0, i_tx_busy, overrun_err_s, frame_err_s,      // STATUS 주소면 여러 플래그를 한 바이트로 묶어서 내보냄
                                    i_rx_full, i_rx_empty, i_tx_full, i_tx_empty } ;  // [7]예약 [6]busy [5]overrun [4]frame [3]rxfull [2]rxempty [1]txfull [0]txempty
        ADDR_INT_EN  : o_rdata = { 4'b0000, int_en } ;                               // INT_EN 주소면 현재 마스크 값을 내보냄
        default      : o_rdata = 8'h00 ;                                             // 그 외 주소는 0 (정의되지 않은 주소 접근 시 안전값)
    endcase
end

// ----------------------------------------------------------------------
// Process 6 : combined interrupt request (combinational)
// TX Empty / RX Full / Frame Err / Overrun Err, each maskable
// ----------------------------------------------------------------------
assign  o_intr = ( int_en[0] & i_tx_empty    )  |   // TX Empty 인터럽트가 켜져있고 실제로 비었으면 1
                  ( int_en[1] & i_rx_full     )  |   // RX Full 인터럽트가 켜져있고 실제로 꽉찼으면 1
                  ( int_en[2] & frame_err_s   )  |   // Frame Err 인터럽트가 켜져있고 에러가 래치되어 있으면 1
                  ( int_en[3] & overrun_err_s )  ;   // Overrun Err 인터럽트가 켜져있고 에러가 래치되어 있으면 1 (넷 중 하나라도 1이면 o_intr=1)

endmodule                                                                   // 모듈 정의 끝
