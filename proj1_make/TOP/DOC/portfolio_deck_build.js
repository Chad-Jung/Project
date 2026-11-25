const pptxgen = require("pptxgenjs");
const { applyTheme } = require("/root/.claude/skills/synced/d6c7b799-1459-4326-b841-1ddbd6a87d46_921b5c1f-d987-466f-acd5-ad056f57e362/pptx/scripts/apply_theme.js");

const SP = "/tmp/claude-0/-home-user-Project/3e30fc78-a722-55d3-8ab7-6834530a58d6/scratchpad";
const U = SP + "/upload/", N = SP + "/notion/";
const OUT = process.argv[2] || "UART_IP_Portfolio_KO.pptx";
const MODE = process.env.DECK || "ALL";   // ALL | FE | BE

const DIM = {
  "a01_block_diagram.png": [3440, 2220], "a02_import_files.png": [3120, 2148],
  "b01_floorplan.png": [1280, 960], "b02_powerplan.png": [1280, 960], "b03_place.png": [1280, 960],
  "b04_density.png": [1021, 858], "b05_cts.png": [1280, 960], "b06_cts_clock.png": [1280, 960],
  "b07_route.png": [1280, 960], "b08_chipfinish.png": [1280, 960], "b09_placeopt_timing.png": [911, 1127],
  "b10_ccopt.png": [845, 768], "b11_clock_trees.png": [908, 726], "b12_skew_groups.png": [906, 632],
  "b13_skew_worst5.png": [736, 262], "b14_postcts_hold_opt.png": [897, 722], "b15_postcts_hold_final.png": [900, 392],
  "b16_sta_coverage.png": [788, 249], "b17_sta_setup.png": [697, 179], "b18_sta_parasitics.png": [657, 168],
  "b19_sta_hold.png": [716, 118], "w01_func_full.png": [1221, 596], "w02_func_frame.png": [1224, 592],
  "w03_func_delay.png": [1222, 596], "w04_pre_full.png": [1006, 596], "w05_pre_frame.png": [1102, 597],
  "w06_pre_delay.png": [1102, 597], "w07_pre_rdata.png": [1245, 595], "w08_post_max_full.png": [1360, 724],
  "w09_post_max_frame.png": [1363, 727], "w10_post_max_delay.png": [1363, 722], "w11_post_min_delay.png": [1106, 597],
  "01_funcsim_TEST_PASSED.png": [726, 834], "09_syn_report_constraint.png": [527, 377], "10_syn_qor.png": [553, 767],
  "12_ec_statistics.png": [1098, 959], "13_ec_verification_PASS.png": [1099, 956], "14_presim_TEST_PASSED.png": [726, 845],
  "15_sta_pre_coverage.png": [890, 341],
  "04_waveform_bit_width_cursor.png": [1328, 783], "05_waveform_framing_error.png": [1329, 780],
};

const THEME = {
  name: "UART Silicon",
  headFontFace: "Malgun Gothic",
  bodyFontFace: "Malgun Gothic",
  colors: {
    dk1: "1B2329", lt1: "FFFFFF", dk2: "14232B", lt2: "EEF2F4",
    accent1: "D9822B", accent2: "2A9D8F", accent3: "5B6B75", accent4: "C0392B",
    accent5: "8FA3AD", accent6: "F2C14E", hlink: "2A9D8F", folHlink: "5B6B75",
  },
};
const HEX = THEME.colors;

const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE"; // 13.333 x 7.5
pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
pres.title = "UART IP 설계 포트폴리오";
pres.author = "YECHAN JUNG";
const C = pres.SchemeColor;
const W = 13.333, H = 7.5, MX = 0.6;
const MONO = "Courier New";

// ---------- layouts ----------
pres.defineSlideMaster({
  title: "TITLE_DARK",
  background: { color: C.text2 },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: MX, y: 2.2, w: 7.2, h: 1.6, fontSize: 40, bold: true, color: C.background1, valign: "bottom", align: "left" }, text: "" } },
    { placeholder: { options: { name: "body", type: "body", x: MX, y: 3.95, w: 7.2, h: 1.6, fontSize: 18, color: C.accent5, valign: "top", align: "left" }, text: "" } },
  ],
});
pres.defineSlideMaster({
  title: "SECTION_DARK",
  background: { color: C.text2 },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: MX, y: 1.2, w: 6.4, h: 1.2, fontSize: 40, bold: true, color: C.background1, valign: "bottom", align: "left" }, text: "" } },
    { placeholder: { options: { name: "body", type: "body", x: MX, y: 2.5, w: 6.5, h: 0.9, fontSize: 16, color: C.accent5, valign: "top", align: "left" }, text: "" } },
  ],
  slideNumber: { x: W - 1.0, y: H - 0.5, w: 0.5, h: 0.3, fontSize: 10, color: C.accent5, align: "right" },
});
pres.defineSlideMaster({
  title: "CONTENT",
  background: { color: C.background1 },
  margin: [0.5, 0.6, 0.6, 0.6],
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: MX, y: 0.3, w: 10.3, h: 0.75, fontSize: 28, bold: true, color: C.text2, valign: "middle", margin: 0, align: "left" }, text: "" } },
    { text: { text: "UART IP · Cadence 45 nm Digital Flow", options: { x: MX, y: H - 0.42, w: 6, h: 0.3, fontSize: 10, color: C.accent3, margin: 0 } } },
  ],
  slideNumber: { x: W - 1.1, y: H - 0.42, w: 0.5, h: 0.3, fontSize: 10, color: C.accent3, align: "right" },
});

// ---------- helpers ----------
function fit(file, x, y, w, h, align = "center") {
  const [iw, ih] = DIM[file];
  const r = Math.min(w / iw, h / ih);
  const dw = iw * r, dh = ih * r;
  const dx = align === "left" ? x : x + (w - dw) / 2;
  return { x: dx, y: y + (h - dh) / 2, w: dw, h: dh };
}
function img(slide, dir, file, x, y, w, h, opts = {}) {
  const g = fit(file, x, y, w, h, opts.align);
  slide.addShape(pres.shapes.RECTANGLE, { x: g.x - 0.03, y: g.y - 0.03, w: g.w + 0.06, h: g.h + 0.06, fill: { color: C.background2 }, line: { color: C.accent5, width: 0.75 }, objectName: "frame " + file });
  slide.addImage({ path: dir + file, x: g.x, y: g.y, w: g.w, h: g.h, altText: opts.alt || file, objectName: file });
  if (opts.cap) slide.addText(opts.cap, { x: g.x, y: g.y + g.h + 0.06, w: Math.max(g.w, 2.5), h: 0.3, fontSize: 10.5, color: C.accent3, italic: true, margin: 0, isTextBox: true });
  return g;
}
function tag(slide, label) { // requirement chip (deck motif)
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: W - MX - 1.9, y: 0.42, w: 1.9, h: 0.5, rectRadius: 0.25, fill: { color: C.accent1 }, line: { type: "none" }, objectName: "req tag" });
  slide.addText(label, { x: W - MX - 1.9, y: 0.42, w: 1.9, h: 0.5, fontSize: 13, bold: true, color: C.background1, align: "center", valign: "middle", margin: 0, isTextBox: true });
}
function content(title, label, section) {
  const s = pres.addSlide({ masterName: "CONTENT", sectionTitle: section });
  s.addText(title, { placeholder: "title" });
  if (label) tag(s, label);
  return s;
}
function bullets(slide, items, x, y, w, h, size = 14) {
  slide.addText(items.map((t, i) => {
    const o = { bullet: true, paraSpaceAfter: 6 };
    if (i < items.length - 1) o.breakLine = true;
    if (Array.isArray(t)) return t.map((r, j) => ({ text: r.text, options: Object.assign({}, j === 0 ? o : {}, r.options || {}, j < t.length - 1 ? { breakLine: false } : {}) }));
    return { text: t, options: o };
  }).flat(), { x, y, w, h, fontSize: size, color: C.text1, valign: "top", margin: 0.05, isTextBox: true });
}
function table(slide, rows, x, y, w, colW, size = 12, opts = {}) {
  const data = rows.map((r, i) => r.map((c) => {
    const cell = typeof c === "object" ? c : { text: String(c) };
    const o = Object.assign({ fontSize: size, color: C.text1, valign: "middle", margin: [3, 5, 3, 5] }, cell.options || {});
    if (i === 0) Object.assign(o, { bold: true, color: C.background1, fill: { color: C.text2 } });
    else if (i % 2 === 0) o.fill = o.fill || { color: C.background2 };
    return { text: cell.text, options: o };
  }));
  slide.addTable(data, Object.assign({ x, y, w, colW, border: { type: "solid", pt: 0.5, color: HEX.accent5 }, rowH: opts.rowH || 0.32 }, opts));
}
function stat(slide, x, y, w, h, value, label, color) {
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.08, fill: { color: C.background2 }, line: { type: "none" }, objectName: "stat " + label });
  slide.addText(value, { x: x + 0.15, y: y + 0.12, w: w - 0.3, h: h * 0.55, fontSize: 26, bold: true, color: color || C.text2, margin: 0, valign: "middle", isTextBox: true });
  slide.addText(label, { x: x + 0.15, y: y + h * 0.62, w: w - 0.3, h: h * 0.3, fontSize: 12, color: C.accent3, margin: 0, valign: "top", isTextBox: true });
}
function code(slide, text, x, y, w, h, size = 10.5) {
  slide.addShape(pres.shapes.RECTANGLE, { x, y, w, h, fill: { color: C.text2 }, line: { type: "none" }, objectName: "code panel" });
  slide.addText(text, { x: x + 0.15, y: y + 0.12, w: w - 0.3, h: h - 0.24, fontFace: MONO, fontSize: size, color: C.background2, valign: "top", margin: 0, isTextBox: true, paraSpaceAfter: 0 });
}
function note(slide, text, x, y, w, h, color) {
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.08, fill: { color: color || C.background2 }, line: { type: "none" }, objectName: "note" });
  slide.addText(text, { x: x + 0.2, y, w: w - 0.4, h, fontSize: 13, color: C.text1, valign: "middle", margin: 0, isTextBox: true });
}
function pill(slide, x, y, w, text, color) {
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h: 0.42, rectRadius: 0.21, fill: { color: color || C.accent2 }, line: { type: "none" }, objectName: "pill" });
  slide.addText(text, { x, y, w, h: 0.42, fontSize: 12, bold: true, color: C.background1, align: "center", valign: "middle", margin: 0, isTextBox: true });
}

// ======================= SLIDES =======================
// 1. Title
pres.addSection({ title: "개요" });
let s = pres.addSlide({ masterName: "TITLE_DARK", sectionTitle: "개요" });
s.addText(MODE === "FE" ? "UART IP Front-End 포트폴리오" : MODE === "BE" ? "UART IP Back-End 포트폴리오" : "UART IP 설계 포트폴리오", { placeholder: "title" });
const SUB = MODE === "FE" ? ["RTL → Gate Netlist · Cadence 45 nm Front-End Flow", "Xcelium · Genus · Conformal LEC · Tempus", "Function Sim · Synthesis · EC · Pre-layout Sim / STA"]
  : MODE === "BE" ? ["Gate Netlist → GDS Sign-off · Cadence 45 nm Back-End Flow", "Innovus · Tempus · Conformal LEC · Xcelium", "Floorplan · CTS · Route · STA · Post-layout EC / Sim"]
  : ["RTL → GDS Sign-off · Cadence 45 nm Digital Flow", "Front-End (Xcelium · Genus · Conformal · Tempus)", "Back-End (Innovus · Tempus)"];
s.addText([
  { text: SUB[0], options: { breakLine: true } },
  { text: SUB[1], options: { breakLine: true, fontSize: 14 } },
  { text: SUB[2], options: { fontSize: 14 } },
], { placeholder: "body" });
s.addText("YECHAN JUNG  ·  Cadence Academy Certificate Project", { x: MX, y: 6.3, w: 7, h: 0.4, fontSize: 13, color: C.accent1, margin: 0, isTextBox: true });
const COVER = MODE === "FE" ? "a01_block_diagram.png" : "b08_chipfinish.png";
s.addShape(pres.shapes.RECTANGLE, { x: 8.35, y: 1.15, w: 4.4, h: 5.2, fill: { color: C.background1 }, line: { type: "none" }, objectName: "cover card" });
s.addImage({ path: U + COVER, ...fit(COVER, 8.45, 1.25, 4.2, 4.6), altText: "Cover image", objectName: "cover image" });
s.addText(MODE === "FE" ? "블록 다이어그램" : "최종 레이아웃 (Chip Finish)", { x: 8.45, y: 5.9, w: 4.2, h: 0.35, fontSize: 11, color: C.accent3, align: "center", margin: 0, isTextBox: true });

// 2. Summary
s = content("프로젝트 요약", null, "개요");
const st = [
  ["+12.938 ns", "최종 Setup WNS (SS, Tempus)", C.text2], ["+0.059 ns", "최종 Hold WNS (FF, Tempus)", C.text2],
  ["0 / 0", "DRC / Connectivity", C.accent2], ["PASS", "EC 2회 (223 compare points)", C.accent2],
  ["4 / 4", "TEST PASSED (Func · Pre · Post max · min)", C.accent2], ["52 µW", "Static Power (SS, 16 ns)", C.accent1],
];
const STF = [
  ["+14,996.8 ps", "합성 Setup WNS (16 ns 클럭)", C.text2], ["563 · 2,984.7 µm²", "합성 셀 수 · 면적", C.text2],
  ["0", "합성 스펙 위반 (constraint)", C.accent2], ["PASS", "EC RTL ↔ 합성 (223 points)", C.accent2],
  ["71 / 71", "Function Sim TEST PASSED", C.accent2], ["69 / 69", "Pre-layout Sim TEST PASSED", C.accent1],
];
const STB = [
  ["+12.938 ns", "최종 Setup WNS (SS, Tempus)", C.text2], ["+0.059 ns", "최종 Hold WNS (FF, Tempus)", C.text2],
  ["0 / 0", "DRC / Connectivity", C.accent2], ["169", "Hold 수리 버퍼 (CTS 106 + Route 63)", C.accent1],
  ["PASS", "Post-layout EC (223 points)", C.accent2], ["52 µW", "Static Power (SS, 16 ns)", C.accent1],
];
(MODE === "FE" ? STF : MODE === "BE" ? STB : st).forEach((v, i) => stat(s, MX + (i % 3) * 4.08, 1.3 + Math.floor(i / 3) * 1.45, 3.85, 1.25, v[0], v[1], v[2]));
const flow = ["RTL", "Function Sim", "Synthesis", "Pre EC · Sim · STA", "Auto PnR", "Post EC", "Post STA", "Post Sim"];
const fw = (W - 2 * MX - 7 * 0.15) / 8;
flow.forEach((f, i) => {
  const x = MX + i * (fw + 0.15);
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 4.45, w: fw, h: 0.75, rectRadius: 0.1, fill: { color: i < 4 ? C.text2 : C.accent1 }, line: { type: "none" }, objectName: "flow " + f });
  s.addText(f, { x, y: 4.45, w: fw, h: 0.75, fontSize: 12, bold: true, color: C.background1, align: "center", valign: "middle", margin: 2, isTextBox: true });
});
s.addText("Front-End", { x: MX, y: 5.28, w: 4 * fw + 0.45, h: 0.3, fontSize: 12, color: C.text2, bold: true, align: "center", margin: 0, isTextBox: true });
s.addText("Back-End · Sign-off", { x: MX + 4 * (fw + 0.15), y: 5.28, w: 4 * fw + 0.45, h: 0.3, fontSize: 12, color: C.accent1, bold: true, align: "center", margin: 0, isTextBox: true });
bullets(s, [
  "사양서(UART IP Spec Rev 1.0)만으로 RTL 6개 모듈 설계 → 블록 단위 PnR → Sign-off까지 전 과정 수행",
  "클럭: 목표 50 MHz(20 ns), 합성·PnR 16 ns(20% 마진), 시뮬레이션 14 ns(30% 마진) · GPDK045",
], MX, 5.75, W - 2 * MX, 0.9, 14);

// ======================= FRONT-END =======================
if (MODE !== "BE") {
pres.addSection({ title: "Front-End" });
s = pres.addSlide({ masterName: "SECTION_DARK", sectionTitle: "Front-End" });
s.addText("Front-End", { placeholder: "title" });
s.addText("RTL → Function Sim → 합성 → Pre-layout Sim / EC / STA", { placeholder: "body" });
[["(a)", "Design Logic Diagram + Spec"], ["(b)", "Function Simulation + Waveform"], ["(c)", "Synthesis Script · Constraint · Setup Report"], ["(d)", "Pre-layout Simulation · 타이밍 오차"]].forEach((r, i) => {
  const y = 3.7 + i * 0.7;
  s.addShape(pres.shapes.OVAL, { x: MX, y, w: 0.5, h: 0.5, fill: { color: C.accent1 }, line: { type: "none" }, objectName: "num " + r[0] });
  s.addText(r[0], { x: MX, y, w: 0.5, h: 0.5, fontSize: 12, bold: true, color: C.background1, align: "center", valign: "middle", margin: 0, isTextBox: true });
  s.addText(r[1], { x: MX + 0.7, y, w: 6, h: 0.5, fontSize: 16, color: C.background1, valign: "middle", margin: 0, isTextBox: true });
});
s.addShape(pres.shapes.RECTANGLE, { x: 7.4, y: 1.0, w: 5.35, h: 5.5, fill: { color: C.background1 }, line: { type: "none" }, objectName: "diagram card" });
s.addImage({ path: U + "a01_block_diagram.png", ...fit("a01_block_diagram.png", 7.5, 1.1, 5.15, 5.3), altText: "Block diagram", objectName: "block diagram small" });

// FE(a) block diagram
s = content("Design Logic Diagram", "FE (a)", "Front-End");
img(s, U, "a01_block_diagram.png", MX, 1.2, 8.9, 5.35, { cap: "_UART_TOP 하위 모듈 6개 · 신호 연결 · 사양 · 레지스터 맵" });
const df = [["송신", "REG_IF → TX_FIFO → UART_TX → o_txd"], ["수신", "i_rxd → UART_RX(2-flop 동기화, mid-bit) → RX_FIFO → REG_IF"], ["틱", "BAUD_GEN → osr_tick 16x → TX / RX"], ["상태 · 인터럽트", "FIFO full/empty, tx_busy, frame/overrun err → STATUS, o_intr"]];
df.forEach((r, i) => {
  const y = 1.25 + i * 1.38;
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 9.8, y, w: 2.95, h: 1.22, rectRadius: 0.08, fill: { color: C.background2 }, line: { type: "none" }, objectName: "flow card " + i });
  s.addText(r[0], { x: 9.95, y: y + 0.08, w: 2.7, h: 0.32, fontSize: 14, bold: true, color: C.accent1, margin: 0, isTextBox: true });
  s.addText(r[1], { x: 9.95, y: y + 0.42, w: 2.7, h: 0.75, fontSize: 11.5, color: C.text1, margin: 0, valign: "top", isTextBox: true });
});

// FE(a) spec + RTL
s = content("사양과 RTL 모듈 구성", "FE (a)", "Front-End");
table(s, [["항목", "사양 (Spec Rev 1.0)"],
  ["Frame", "8-bit, Start 1 + Data 8 (LSB first) + Stop 1, No parity"],
  ["Baud rate", "115,200 bps (DIVISOR 27 → +0.47%)"],
  ["Clock", "CLK_FREQ 50 MHz (파라미터)"],
  ["Oversampling", "16x, mid-bit(tick 7) 샘플링"],
  ["FIFO", "TX / RX 각 8-depth × 8-bit 동기식"],
  ["Interrupt", "TX empty | RX full | frame err | overrun"],
  ["Register", "TX_DATA 0x0 · RX_DATA 0x1 · STATUS 0x2 · INT_EN 0x3 · INT_CLR 0x4 (W1C)"]],
  MX, 1.35, 5.9, [1.5, 4.4], 12, { rowH: 0.5 });
table(s, [["모듈", "구현 포인트"],
  ["_UART_TOP", "5개 서브모듈 연결, 파라미터 CLK_FREQ · BAUD_RATE · OSR"],
  ["_BAUD_GEN_16X", "DIVISOR로 카운터 폭 자동 계산, 1-clk 틱"],
  ["_SYNC_FIFO_8x8", "wrap-bit 포인터 full/empty, 출력 레지스터"],
  ["_UART_TX", "IDLE→START→DATA→STOP, 비트당 16 tick"],
  ["_UART_RX", "2-flop 동기화, false start 검출, stop 후 push/에러"],
  ["_UART_REG_IF", "sticky 에러 + W1C, 인터럽트 OR"]],
  6.85, 1.35, 5.9, [1.75, 4.15], 12, { rowH: 0.57 });

// FE(b) test plan
s = content("Function Simulation — 검증 시나리오", "FE (b)", "Front-End");
table(s, [["Test", "내용"],
  ["T1", "리셋 값 (STATUS 0x05, INT_EN 0, txd 1, intr 0)"], ["T2", "1바이트(0x5A) 루프백 + TX 라인 모니터"],
  ["T3", "8바이트 연속 = FIFO depth, rx_full"], ["T4", "TX full 쓰기 무시, RX overrun, W1C"],
  ["T5", "Framing error (stop=0) → 폐기, sticky, 인터럽트"], ["T6", "False start (반 비트 미만 노이즈)"],
  ["T7", "외부 송신기 8프레임 연속 수신"], ["T8", "TX empty 인터럽트"],
  ["T9", "비트 폭: data/stop 432 clk, start 15~16 tick"], ["T10", "레지스터 맵 (W-only, 미정의 주소 = 0)"],
  ["T11", "RX full 인터럽트, 비트별 W1C, 인터럽트 OR"]],
  MX, 1.3, 7.4, [0.8, 6.6], 12, { rowH: 0.42 });
img(s, N, "01_funcsim_TEST_PASSED.png", 8.4, 1.3, 4.3, 4.35, { cap: "SimVision Console — TEST PASSED" });
note(s, "Self-checking TB · [PASS] 71 / [FAIL] 0 · clk 14 ns (30% 마진), 비트 6,048 ns", 8.4, 6.05, 4.3, 0.7, C.background2);

// FE(b) waveforms
s = content("Function Simulation — Waveform", "FE (b)", "Front-End");
img(s, U, "w01_func_full.png", MX, 1.3, 5.95, 3.5, { cap: "전체 0 ~ 3,088 µs: 루프백(T2~T6) · 외부 입력(T7) · T8~T11" });
img(s, U, "w02_func_frame.png", 6.78, 1.3, 5.95, 3.5, { cap: "T8: 0x3C, 0xC3 연속 송신 → rxd 루프백, FIFO empty 시 intr" });
table(s, [["확인 항목", "관찰", "판정"],
  ["프레임", "0x3C = start 0 · 0 0 1 1 1 1 0 0 · stop 1 (LSB first)", "✓"],
  ["비트 폭", "6,048,000 ps = 16 tick × 27 clk × 14 ns", "✓"],
  ["인터럽트", "두 번째 바이트가 시프트되는 순간 TX FIFO empty → intr 1", "✓"]],
  MX, 5.35, W - 2 * MX, [1.6, 9.6, 0.93], 12, { rowH: 0.36 });

// FE(b) bit width + framing error
s = content("Function Simulation — 비트 폭 · Framing error", "FE (b)", "Front-End");
img(s, U, "04_waveform_bit_width_cursor.png", MX, 1.3, 5.95, 3.6, { cap: "비트 폭 측정 — TimeA 12,173,000 ps / Baseline 18,221,000 ps" });
img(s, U, "05_waveform_framing_error.png", 6.78, 1.3, 5.95, 3.6, { cap: "T5 Framing error — stop=0 프레임 (1,120 ~ 1,200 µs)" });
table(s, [["확인 항목", "관찰", "판정"],
  ["비트 폭 (T9)", "D1 → D2 시작 간격 6,048,000 ps = 16 tick × 27 clk × 14 ns (사양서 7.1, 9)", "✓"],
  ["Framing error (T5)", "0xC3 프레임의 stop = 0 → frame_err 1-clk 펄스, rx_fifo_wr 없음 (프레임 폐기)", "✓"],
  ["인터럽트 (T5)", "frame_err 후 intr = 1 (sticky) → INT_CLR W1C 후 0", "✓"]],
  MX, 5.45, W - 2 * MX, [2.1, 9.1, 0.93], 12, { rowH: 0.36 });

// FE(c) script
s = content("Synthesis Run Script (Genus)", "FE (c)", "Front-End");
code(s, [
  "set TOP_DESIGN _UART_TOP",
  "set LIB_LIST {fast_vdd1v0_basicCells.lib slow_vdd1v0_basicCells.lib pads_SS_s1vg.lib}",
  "set LEF_LIST {gsclib045_tech.lef gsclib045_macro.lef giolib045.lef}",
  "set_db syn_generic_effort high ; set_db syn_map_effort high ; set_db syn_opt_effort high",
  "read_libs $LIB_LIST ; read_physical -lef $LEF_LIST ; read_qrc gpdk045.tch",
  "read_hdl $RTL_SOURCES          ;# RTL/UART 6 modules",
  "elaborate $TOP_DESIGN ; uniquify $TOP_DESIGN",
  "check_design > report/00_check_design.rpt",
  "source ./cons/uart.sdc ; source ./cons/dont_use_45nm.tcl",
  "check_timing_intent > report/01_check_timing_intent.rpt",
  "syn_generic ; syn_map ; syn_opt",
  "report_constraint -all_violators > report/06_report_constraint.rpt",
  "report_qor    > report/19_SYN_qor.rpt",
  "report_timing -nworst 100 -net > report/20_SYN_timing.rpt",
  "write_hdl > mapped/_UART_TOP_syn_final.v",
  "write_sdc > mapped/_UART_TOP_syn_final.sdc",
  "write_sdf -recrem split -setuphold split > mapped/_UART_TOP_delays.sdf",
].join("\n"), MX, 1.3, 8.0, 5.4, 11);
[["Read", "라이브러리 · LEF · QRC · RTL"], ["Constrain", "SDC + dont_use, intent 검사"], ["Synthesize", "generic → map → opt (effort high)"], ["Report", "check · constraint · QoR · timing"], ["Write", "넷리스트 · SDC · SDF → EC / Sim / PnR"]].forEach((r, i) => {
  const y = 1.3 + i * 1.1;
  s.addShape(pres.shapes.OVAL, { x: 8.95, y: y + 0.1, w: 0.55, h: 0.55, fill: { color: C.accent1 }, line: { type: "none" }, objectName: "step " + i });
  s.addText(String(i + 1), { x: 8.95, y: y + 0.1, w: 0.55, h: 0.55, fontSize: 14, bold: true, color: C.background1, align: "center", valign: "middle", margin: 0, isTextBox: true });
  s.addText(r[0], { x: 9.65, y, w: 3.1, h: 0.38, fontSize: 15, bold: true, color: C.text2, margin: 0, isTextBox: true });
  s.addText(r[1], { x: 9.65, y: y + 0.4, w: 3.1, h: 0.5, fontSize: 12, color: C.accent3, margin: 0, valign: "top", isTextBox: true });
});

// FE(c) constraint
s = content("Constraint (uart.sdc)", "FE (c)", "Front-End");
code(s, [
  "create_clock -period 16 -name MAIN_CLOCK [get_ports clk]",
  "set_clock_latency -source -max 0.2 [get_clocks MAIN_CLOCK]",
  "set_clock_latency -max 0.2 [get_clocks MAIN_CLOCK]",
  "set_clock_uncertainty -setup 0.1 [get_clocks MAIN_CLOCK]",
  "set_clock_transition 0.1 [get_clocks MAIN_CLOCK]",
  "set_input_delay  -max 0.1  -clock MAIN_CLOCK [all_inputs]",
  "set_input_delay  -min 0.01 -clock MAIN_CLOCK [all_inputs]",
  "remove_input_delay [get_ports clk]",
  "set_output_delay -max 0.1   -clock MAIN_CLOCK [all_outputs]",
  "set_output_delay -min -0.01 -clock MAIN_CLOCK [all_outputs]",
  "set_driving_cell -lib_cell PADDI -pin Y [inputs except clk]",
  "set_load [load_of PADDO/A] [all_outputs]",
  "set_operating_conditions -max PVT_0P9V_125C -min PVT_1P1V_0C",
  "set_ideal_network [get_ports \"clk clr_n\"]",
  "set_false_path -from [get_ports i_rxd]",
  "set_false_path -from [get_ports clr_n]",
].join("\n"), MX, 1.3, 7.0, 5.4, 11);
table(s, [["제약", "근거"],
  ["Clock 16 ns", "목표 20 ns × 80% → 20% 마진 합성"],
  ["Latency / Uncertainty", "소스·네트워크 0.2 ns, setup 0.1 ns"],
  ["I/O delay", "max 0.1 / min 0.01 ns (블록 경계 예산)"],
  ["PADDI / PADDO", "패드 없는 코어 → 포트 구동·부하를 보수적으로 가정"],
  ["Corner", "Setup = SS 0.9 V 125 °C, Hold = FF 1.1 V 0 °C"],
  ["Ideal network", "clk · clr_n 버퍼링은 CTS에 맡김"],
  ["False path", "i_rxd: 2-flop 동기화 / clr_n: SoC에서 해제 동기화"]],
  7.85, 1.3, 4.9, [1.7, 3.2], 12, { rowH: 0.66 });

// FE(c) timing report
s = content("Timing Report (Setup) · QoR", "FE (c)", "Front-End");
img(s, N, "10_syn_qor.png", MX, 1.3, 3.9, 5.4, { cap: "19_qor — WNS +14,996.8 ps" });
img(s, N, "09_syn_report_constraint.png", 4.85, 1.3, 3.9, 2.9, { cap: "report_constraint — 위반 0" });
[["+14,996.8 ps", "Setup WNS (16 ns 중 1 ns 사용)"], ["0 / 0", "TNS / Violating paths"], ["563", "셀 (Sequential 213)"], ["2,984.7 µm²", "Total area (cell 2,278.7)"]].forEach((v, i) => stat(s, 9.05 + 0 * i, 1.3 + i * 1.38, 3.7, 1.2, v[0], v[1], i === 0 ? C.accent2 : C.text2));
note(s, "check_design 구조 문제 0 · check_timing_intent 0 · 로그 에러 0", 4.85, 5.0, 3.9, 0.95);

// FE: EC + STA pre
s = content("Pre-layout EC · STA", "FE 검증", "Front-End");
img(s, N, "13_ec_verification_PASS.png", MX, 1.3, 4.6, 4.2, { cap: "Conformal LEC — Compare Results PASS" });
img(s, N, "15_sta_pre_coverage.png", 5.5, 1.3, 7.2, 2.6, { cap: "Tempus — report_analysis_coverage, Violated 0" });
table(s, [["검증", "결과"],
  ["EC (RTL ↔ 합성)", "223 compare points Equivalent, PASS"],
  ["STA Setup / Hold", "+13.951 ns / +0.039 ns, 위반 0"],
  ["비동기 입력", "i_rxd · clr_n false path + SoC 연동 조건 명시"]],
  5.5, 4.45, 7.2, [2.2, 5.0], 12, { rowH: 0.42 });

// FE(d) pre-layout sim
s = content("Pre-layout Simulation", "FE (d)", "Front-End");
table(s, [["항목", "내용"],
  ["입력", "합성 넷리스트 + Genus SDF + 셀 Verilog 모델 (slow)"],
  ["Testbench", "Function과 동일, +define+sdf_gate 만 변경"],
  ["SDF 적용", "$sdf_annotate(..., \"MAXIMUM\")"],
  ["Annotation", "Pathdelay 1,440 / 3,009, Tcheck 770 / 2,624, 에러 0"],
  ["결과", "TEST PASSED 69/69, 종료 3,087,972 ns (RTL과 동일)"]],
  MX, 1.3, 7.2, [1.6, 5.6], 12, { rowH: 0.48 });
note(s, "문제 해결: Genus SDF는 max 칸만 기록 → 기본(TYPICAL) 적용 시 지연 0. \"MAXIMUM\" 지정으로 실제 셀 지연 반영", MX, 4.45, 7.2, 1.0, C.background2);
note(s, "게이트 레벨: RTL 내부 신호를 보는 검사 2개는 define으로 제외 (71 → 69)", MX, 5.65, 7.2, 0.8, C.background2);
img(s, N, "14_presim_TEST_PASSED.png", 8.3, 1.3, 4.4, 4.9, { cap: "SimVision Console (Pre-layout) — TEST PASSED" });

// FE(d) timing diff
s = content("타이밍 오차 — Function vs Pre-layout", "FE (d)", "Front-End");
img(s, U, "w03_func_delay.png", MX, 1.3, 5.95, 2.95, { cap: "Function @231 ns — clk와 txd 동시 변화 (0 ps)" });
img(s, U, "w06_pre_delay.png", 6.78, 1.3, 5.95, 2.95, { cap: "Pre-layout @231 ns — txd 231,080 ps (+80 ps)" });
table(s, [["비교 지점", "Function", "Pre-layout", "원인"],
  ["clk ↑ → txd ↓ (231,000 ps)", "0 ps", "80 ps", "플립플롭 clk→Q 셀 지연"],
  ["addr 변경 → rdata 안정 (232,000 ps)", "0 ps (즉시 45)", "190~250 ps, 중간값 01", "읽기 MUX 조합 경로, 비트별 지연 차이"],
  ["판정", "PASS", "PASS", "샘플링이 클록 에지 2 ns 전 → 지연보다 충분히 늦음"]],
  MX, 4.85, W - 2 * MX, [3.4, 1.7, 2.3, 4.73], 12, { rowH: 0.42 });

// FE(d) glitch
s = content("타이밍 오차 — 조합 출력 글리치", "FE (d)", "Front-End");
img(s, U, "w07_pre_rdata.png", MX, 1.3, 7.9, 4.6, { cap: "Pre-layout — rdata가 232,190 ps에 01을 거쳐 45로 안정" });
bullets(s, [
  [{ text: "현상  ", options: { bold: true, color: C.accent1 } }, { text: "STATUS 읽기에서 rdata 00 → 01 → 45" }],
  [{ text: "원인  ", options: { bold: true, color: C.accent1 } }, { text: "i_addr → o_rdata 읽기 MUX는 조합 경로. bit0이 먼저, bit2·6이 늦게 바뀌어 중간값 발생" }],
  [{ text: "영향  ", options: { bold: true, color: C.accent1 } }, { text: "TB와 CPU는 다음 클럭 에지에 샘플링 → 0.25 ns 안에 안정되므로 기능 영향 없음" }],
  [{ text: "연결  ", options: { bold: true, color: C.accent1 } }, { text: "같은 경로가 Back-End에서 Hold 위반(−8 ps)으로 나타나 Route 후 수리" }],
], 8.85, 1.35, 3.9, 5.2, 14);

}
// ======================= BACK-END =======================
if (MODE !== "FE") {
pres.addSection({ title: "Back-End" });
s = pres.addSlide({ masterName: "SECTION_DARK", sectionTitle: "Back-End" });
s.addText("Back-End", { placeholder: "title" });
s.addText("Floorplan → PowerPlan → Place → CTS → Route → Chip Finish → Sign-off", { placeholder: "body" });
[["(a)", "APR 전 과정 Script"], ["(b)", "Import 파일 정리"], ["(c)", "단계별 캡처 (고대비 반전)"], ["(d)", "NanoRoute 후 타이밍"], ["(e)", "Hold 변화 · 버퍼 삽입"], ["(f)", "ECO"], ["(g)", "최종 타이밍 리포트"]].forEach((r, i) => {
  const y = 3.55 + i * 0.47;
  s.addShape(pres.shapes.OVAL, { x: MX, y, w: 0.38, h: 0.38, fill: { color: C.accent1 }, line: { type: "none" }, objectName: "num " + r[0] });
  s.addText(r[0], { x: MX, y, w: 0.38, h: 0.38, fontSize: 10, bold: true, color: C.background1, align: "center", valign: "middle", margin: 0, isTextBox: true });
  s.addText(r[1], { x: MX + 0.55, y, w: 6, h: 0.38, fontSize: 14, color: C.background1, valign: "middle", margin: 0, isTextBox: true });
});
s.addShape(pres.shapes.RECTANGLE, { x: 7.4, y: 1.0, w: 5.35, h: 5.5, fill: { color: C.background1 }, line: { type: "none" }, objectName: "route card" });
s.addImage({ path: U + "b06_cts_clock.png", ...fit("b06_cts_clock.png", 7.5, 1.1, 5.15, 5.3), altText: "CTS clock nets", objectName: "cts small" });

// BE(a) scripts
s = content("APR 전 과정 Script (Innovus · Tempus)", "BE (a)", "Back-End");
const scr = [
  ["0_InitDesign", "init_design (MMMC)\nfloorPlan -r 1 0.7 10…\neditPin L/R M3, T/B M4\nsaveDesign InitDesign"],
  ["1_PowerPlan", "globalNetConnect VDD/VSS\naddRing M3/M4 w2\nsroute corePin (M1)\naddStripe M4 ×3 pair"],
  ["2_PlaceOpt", "place_design\nearlyGlobalRoute\nplace_opt_design\naddTieHiLo TIEHI"],
  ["3_PostCTSopt", "ccopt_design (skew 0.01)\nset_propagated_clock\noptDesign -postCTS\nholdTargetSlack 0.02 -hold"],
  ["4_Route+Power", "routeDesign -globalDetail\nverify_drc / Connectivity\noptDesign -postRoute -hold ×2\nreport_power static"],
  ["5_ChipFinish", "addFiller FILL1~64\nsaveNetlist -flat / hier\nwrite_sdf · writeTimingCon\nstreamOut GDS"],
  ["tempus.tcl", "read_design RouteDesign.dat\nreport_analysis_coverage\nreport_timing late/early\nwrite_sdf wst / bst"],
  ["snap.tcl", "restoreDesign <stage>.dat\nfit ; dumpToGIF\n단계별 캡처 자동화\n(snap_all.sh)"],
];
scr.forEach((c, i) => {
  const cw = (W - 2 * MX - 3 * 0.25) / 4, x = MX + (i % 4) * (cw + 0.25), y = 1.3 + Math.floor(i / 4) * 2.75;
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w: cw, h: 2.5, rectRadius: 0.08, fill: { color: i < 6 ? C.background2 : C.background1 }, line: { color: i < 6 ? HEX.lt2 : HEX.accent5, width: 0.75 }, objectName: "script " + c[0] });
  s.addText(c[0], { x: x + 0.15, y: y + 0.12, w: cw - 0.3, h: 0.4, fontSize: 15, bold: true, color: i < 6 ? C.accent1 : C.accent2, margin: 0, isTextBox: true });
  s.addText(c[1], { x: x + 0.15, y: y + 0.6, w: cw - 0.3, h: 1.8, fontFace: MONO, fontSize: 11, color: C.text1, valign: "top", margin: 0, isTextBox: true });
});

// BE(b) import files
s = content("Import 파일 정리", "BE (b)", "Back-End");
table(s, [["구분", "파일", "출처 · 설정"],
  ["Gate netlist", "_UART_TOP_syn_final.v", "Genus 출력 (계층 유지) · init_verilog"],
  ["Constraint", "_UART_TOP_pnr.sdc", "합성 SDC − set_ideal_network · constraint mode FUNC"],
  ["MMMC", "_UART_TOP.mmmc.view", "corner 2 · view 2 · init_mmmc_file"],
  ["Tech / Cell LEF", "gsclib045_tech / macro / multibitsDFF", "GPDK045 · init_lef_file"],
  ["Timing lib (max)", "slow_vdd1v0_*, pads_SS", "SS_Max_0p90v_125c"],
  ["Timing lib (min)", "fast_vdd1v0_*, pads_FF", "FF_Min_1p10v_0c"],
  ["RC model", "cap table, QRC gpdk045.tch", "RC corner WORST 125 °C / BEST 0 °C"],
  ["Top / Power", "_UART_TOP, VDD / VSS", "init_top_cell, init_pwr/gnd_net"],
  ["Pin", "editPin (IO 파일 없음)", "좌·우 Metal3 23개, 위·아래 Metal4 4개"]],
  MX, 1.3, 7.9, [1.75, 3.0, 3.15], 11.5, { rowH: 0.45 });
table(s, [["Analysis view", "Library set · RC", "용도"],
  ["FUNC_SS_WORST", "SS_Max_0p90v_125c · WORST", "Setup"],
  ["FUNC_FF_BEST", "FF_Min_1p10v_0c · BEST", "Hold"]],
  8.85, 1.3, 3.9, [1.4, 1.85, 0.65], 10.5, { rowH: 0.55 });
note(s, "블록 단위 PnR: IO pad 없이 핀만 배치\n배선층 Metal1~4 · 이용률 70%\nDie 77.8 × 76.57 µm", 8.85, 3.2, 3.9, 1.5);
note(s, "라이브러리는 파일 이름과 PVT만 기재 (PDK 내용 · 경로 비공개)", 8.85, 4.95, 3.9, 0.9, C.background2);

// BE(c) floorplan + power
s = content("Floorplan · PowerPlan", "BE (c)", "Back-End");
img(s, U, "b01_floorplan.png", MX, 1.3, 4.2, 4.6, { cap: "① Floorplan — row · 핀 27개" });
img(s, U, "b02_powerplan.png", 5.0, 1.3, 4.2, 4.6, { cap: "② PowerPlan — Ring · Rail · Stripe" });
bullets(s, [
  "floorPlan -r 1 0.7 10: 종횡비 1, 이용률 70%, 링 자리 10 µm",
  "핀: 좌 14 / 우 9 (M3), 위 clk·clr_n / 아래 i_rxd·o_txd (M4)",
  "Core ring M3/M4 2 µm → 8 wires",
  "M1 rail 102 · M4 stripe 3쌍 (20 µm)",
  "verify_drc 0 · verifyConnectivity 0",
], 9.6, 1.35, 3.15, 5.2, 13);

// BE(c) place
s = content("Placement", "BE (c)", "Back-End");
img(s, U, "b03_place.png", MX, 1.3, 4.2, 4.6, { cap: "③ PlaceOpt — 셀 배치 · 예비 배선" });
img(s, U, "b04_density.png", 5.0, 1.3, 4.2, 4.6, { cap: "Density Map — 최대 bin 0.827" });
stat(s, 9.6, 1.3, 3.15, 1.15, "0.00%", "Overflow H / V");
stat(s, 9.6, 2.6, 3.15, 1.15, "+13.390 ns", "place_opt Setup WNS", C.accent2);
stat(s, 9.6, 3.9, 3.15, 1.15, "72.2%", "Density (562 placed)");
note(s, "RN 상수 핀 3개 → addTieHiLo로 TIEHI 2개 연결", 9.6, 5.2, 3.15, 0.95);

// BE(c) CTS
s = content("Clock Tree Synthesis", "BE (c)", "Back-End");
img(s, U, "b06_cts_clock.png", MX, 1.3, 4.2, 4.6, { cap: "④ CTS — 클록 net 강조" });
img(s, U, "b11_clock_trees.png", 5.0, 1.3, 4.2, 4.6, { cap: "clock_trees.rpt — 버퍼 23 · 인버터 1 · depth 2" });
table(s, [["항목", "결과"], ["클록 셀", "24개, 47.5 µm²"], ["Depth", "2 / 2"], ["Sink", "213"], ["Skew SS / FF", "0.056 / 0.018 ns"], ["최악 실제 Skew", "0.047 ns"], ["Leaf slew", "0.102 ns"]],
  9.6, 1.3, 3.15, [1.65, 1.5], 12, { rowH: 0.48 });
note(s, "negedge 3개 = DFFNSR + 클록 인버터 (실제 clk ↑ 동작)", 9.6, 4.9, 3.15, 1.0);

// BE(c) route + finish
s = content("Route · Chip Finish", "BE (c)", "Back-End");
img(s, U, "b07_route.png", MX, 1.3, 4.2, 4.6, { cap: "⑤ RouteDesign — M1~M4 배선" });
img(s, U, "b08_chipfinish.png", 5.0, 1.3, 4.2, 4.6, { cap: "⑥ ChipFinish — Filler 573" });
bullets(s, [
  "routeDesign -globalDetail: 0 error",
  "DRC 0 · Connectivity 0 (Route 후, Finish 후)",
  "Filler 573 → 인스턴스 1,367 (로직 794)",
  "GDS: 핀 27, 전원 M1 102 · M3 4 · M4 10",
  "출력: flat 넷리스트(EC), hier 넷리스트(Sim), SDF, SDC, GDS",
], 9.6, 1.35, 3.15, 5.2, 13);

// BE(d)
s = content("NanoRoute 후 타이밍 (Innovus)", "BE (d)", "Back-End");
table(s, [["구분", "all", "reg2reg", "default (I/O)", "Violating"],
  ["Setup WNS (FUNC_SS_WORST)", "+12.938 ns", "+13.021", "+12.938", "0"],
  ["Hold WNS (FUNC_FF_BEST)", "+0.022 ns", "+0.059", "+0.022", "0"],
  ["DRV (cap / tran / fanout / length)", "0 / 0 / 0 / 0", "", "", ""],
  ["Density", "82.99%", "", "", ""]],
  MX, 1.3, W - 2 * MX, [4.0, 2.2, 1.9, 2.2, 1.83], 13, { rowH: 0.5 });
stat(s, MX, 4.2, 3.85, 1.3, "+12.938 ns", "Setup WNS (16 ns 클럭)", C.accent2);
stat(s, MX + 4.08, 4.2, 3.85, 1.3, "+0.022 ns", "Hold WNS (2차 수리 후)", C.accent2);
stat(s, MX + 8.16, 4.2, 3.95, 1.3, "0", "DRC / Connectivity 위반");
note(s, "RC 추출(extractRC) 후 setup → hold 순서로 최적화 · SI off, single analysis mode", MX, 5.8, W - 2 * MX, 0.7);

// BE(e)
s = content("Hold Timing 변화와 버퍼 삽입", "BE (e)", "Back-End");
s.addChart(pres.charts.BAR, [{ name: "삽입 버퍼", labels: ["Place 후", "CTS 후", "Route 후"], values: [0, 106, 63] }], {
  x: MX, y: 1.3, w: 4.6, h: 3.6, barDir: "col", chartColors: [HEX.accent1], showValue: true, dataLabelPosition: "outEnd",
  dataLabelColor: HEX.dk1, dataLabelFontSize: 12, dataLabelFontFace: "+mn-lt", showTitle: true, title: "단계별 Hold 버퍼 (누적 169)",
  titleFontSize: 13, titleColor: HEX.dk2, titleFontFace: "+mn-lt", showLegend: false,
  catAxisLabelColor: HEX.accent3, valAxisLabelColor: HEX.accent3, catAxisLabelFontFace: "+mn-lt", valAxisLabelFontFace: "+mn-lt",
  catAxisLabelFontSize: 12, valAxisLabelFontSize: 11, valGridLine: { color: HEX.lt2, size: 0.5 }, catGridLine: { style: "none" }, valAxisMaxVal: 120,
});
table(s, [["단계", "Hold WNS", "위반 경로", "버퍼"],
  ["CTS 후", "−0.001 → +0.020 ns", "i_wdata → TX FIFO (8)", "106"],
  ["Route 후", "−0.008 → +0.022 ns", "i_addr → o_rdata (3)", "63"],
  ["Sign-off", "+0.059 ns (Tempus)", "0", "169"]],
  5.5, 1.3, 7.25, [1.2, 2.2, 2.85, 1.0], 12, { rowH: 0.48 });
bullets(s, [
  "원인: 입력 Hold 가정(min 0.01 ns) 대비 CTS 후 내부 클록 약 0.4 ns 지연",
  "holdTargetSlack 0.02로 Route RC 변화 대비 여유 확보",
  "지연 셀 8종 dont_use → 일반 버퍼로 수리 (Density 73.7% → 83.0%)",
  "Setup 여유 유지 (+13.25 → +12.94 ns) · reg2reg는 처음부터 +0.059 ns",
], 5.5, 3.45, 7.25, 2.4, 13);
note(s, "기타 삽입 셀: Setup/DRV 버퍼 FE_OFC 40 · 클록 셀 24 · TIEHI 2", MX, 5.95, W - 2 * MX, 0.6, C.background2);

// BE(f)(g)
s = content("최종 타이밍 리포트 (Tempus Sign-off) · ECO", "BE (f)(g)", "Back-End");
img(s, U, "b16_sta_coverage.png", MX, 1.3, 6.6, 2.15, { cap: "report_analysis_coverage — 전 항목 Violated 0" });
img(s, U, "b17_sta_setup.png", MX, 3.95, 6.6, 1.25, { cap: "Setup 최악 +12.938 ns (U3_RX_FIFO/o_data_reg_0)" });
img(s, U, "b19_sta_hold.png", MX, 5.65, 6.6, 0.9, { cap: "Hold 최악 +0.059 ns (U4_UART_RX/rxd_s_reg)" });
table(s, [["Check", "Violated", "Untested"],
  ["Setup / Hold", "0 / 0", "1 / 1 (i_rxd)"], ["External delay", "0", "0"], ["Recovery / Removal", "0", "88 (clr_n)"], ["Pulse width", "0", "88"], ["RC 반영", "실제 net 823개 100%", ""]],
  7.6, 1.3, 5.15, [1.9, 1.8, 1.45], 12, { rowH: 0.44 });
s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 7.6, y: 4.2, w: 5.15, h: 2.3, rectRadius: 0.08, fill: { color: C.text2 }, line: { type: "none" }, objectName: "eco card" });
s.addText([
  { text: "(f) ECO — 미수행", options: { bold: true, color: C.accent1, fontSize: 16, breakLine: true } },
  { text: "Sign-off STA 위반 0. Hold는 PnR 단계(CTS 후 · Route 후) optDesign -hold로 이미 해결. Untested 개수가 Pre-layout STA와 같아 PnR이 새 미검사 경로를 만들지 않음.", options: { color: C.background1, fontSize: 13 } },
], { x: 7.8, y: 4.3, w: 4.75, h: 2.1, valign: "top", margin: 0, isTextBox: true });

// ======================= SIGN-OFF =======================
pres.addSection({ title: "Sign-off" });
s = content("Post-layout EC · Simulation", "Sign-off", "Sign-off");
table(s, [["검증", "결과"],
  ["Post EC (합성 ↔ PnR)", "PI 17 · PO 10 · DFF 213, 223 Equivalent, Unmapped 0 → PASS"],
  ["Post Sim max (SS)", "계층 넷리스트 + wst SDF → TEST PASSED, FAIL 0"],
  ["Post Sim min (FF)", "계층 넷리스트 + bst SDF → TEST PASSED, FAIL 0"],
  ["문제 해결", "flat 넷리스트 ↔ 계층 SDF 불일치(적용 4%) → hier 넷리스트로 52%"]],
  MX, 1.3, 7.0, [2.1, 4.9], 12, { rowH: 0.52 });
s.addChart(pres.charts.BAR, [{ name: "clk→txd", labels: ["Function", "Pre-layout", "Post min (FF)", "Post max (SS)"], values: [0, 80, 110, 440] }], {
  x: 7.85, y: 1.3, w: 4.9, h: 3.3, barDir: "col", chartColors: [HEX.accent2], showValue: true, dataLabelPosition: "outEnd",
  dataLabelColor: HEX.dk1, dataLabelFontSize: 12, dataLabelFontFace: "+mn-lt", showTitle: true, title: "같은 지점 clk → txd 지연 (ps)",
  titleFontSize: 13, titleColor: HEX.dk2, titleFontFace: "+mn-lt", showLegend: false,
  catAxisLabelColor: HEX.accent3, valAxisLabelColor: HEX.accent3, catAxisLabelFontFace: "+mn-lt", valAxisLabelFontFace: "+mn-lt",
  catAxisLabelFontSize: 11, valAxisLabelFontSize: 11, valGridLine: { color: HEX.lt2, size: 0.5 }, catGridLine: { style: "none" }, valAxisMaxVal: 500,
});
img(s, U, "w10_post_max_delay.png", MX, 4.25, 4.9, 2.4, { cap: "Post max: clk ↑ → txd ↓ 440 ps" });
note(s, "Pre(80 ps)와 Post max(440 ps)의 차이 360 ps = CTS 리포트의 o_txd_reg 클록 Latency 0.356 ns → 클록 트리 지연이 시뮬레이션에서도 확인됨", 5.75, 4.85, 7.0, 1.4);

}
// ======================= PROBLEMS =======================
{
const PR = [
  ["FE", "Pre-layout Sim", "Genus SDF max 칸만 기록 → 지연 0", "$sdf_annotate \"MAXIMUM\""],
  ["FE", "Pre-layout STA", "비동기 입력 Removal / Hold 위반", "i_rxd · clr_n false path + SoC 연동 조건"],
  ["BE", "Placement", "RN 상수 핀이 Tie 셀 없이 연결", "addTieHiLo → TIEHI 2"],
  ["BE", "CTS 후", "입력 → FIFO Hold −1 ps (8 경로)", "holdTargetSlack 0.02 → +0.020 ns"],
  ["BE", "Route 후", "i_addr → o_rdata Hold −8 ps", "postRoute hold 2회 → +0.022 ns"],
  ["BE", "Post EC", ".tcl dofile이 Tcl 모드로 실행", ".do + // 주석"],
  ["BE", "Post Sim", "flat 넷리스트 ↔ 계층 SDF (적용 4%)", "계층 넷리스트 별도 출력 → PASS"],
].filter((r) => MODE === "ALL" || r[0] === MODE).map((r) => r.slice(1));
pres.addSection({ title: "문제 해결" });
s = content("주요 문제 해결 기록", null, "문제 해결");
table(s, [["단계", "문제", "해결"]].concat(PR),
  MX, 1.3, W - 2 * MX, [2.2, 5.0, 4.93], 13, { rowH: 0.62 });
}

// Closing
pres.addSection({ title: "마무리" });
s = pres.addSlide({ masterName: "TITLE_DARK", sectionTitle: "마무리" });
s.addText("정리", { placeholder: "title" });
s.addText(MODE === "FE" ? "사양서에서 게이트 넷리스트까지, 기능과 타이밍을 모두 검증" : MODE === "BE" ? "합성 넷리스트에서 GDS까지, 물리·타이밍 Sign-off를 위반 0으로 마감" : "사양서 한 장에서 Sign-off까지, 모든 단계를 위반 0으로 마감", { placeholder: "body" });
(MODE === "FE" ? [["Function", "11개 시나리오 71/71 PASS"], ["Synthesis", "WNS +14,996.8 ps · 2,984.7 µm² · 위반 0"], ["Equivalence", "RTL ↔ 합성 PASS (223 points)"], ["Pre-layout", "Sim 69/69 PASS · STA 위반 0"]]
 : MODE === "BE" ? [["Timing", "Setup +12.938 ns / Hold +0.059 ns (Tempus)"], ["Physical", "DRC 0 · Connectivity 0 · Filler · GDS 출력"], ["Equivalence", "합성 ↔ PnR PASS (223 points)"], ["Dynamic", "Post-layout max / min TEST PASSED"]]
 : [["Timing", "Setup +12.938 ns / Hold +0.059 ns (Tempus)"], ["Physical", "DRC 0 · Connectivity 0 · Filler · GDS 출력"], ["Equivalence", "RTL ↔ 합성 ↔ PnR 모두 PASS"], ["Dynamic", "Function · Pre · Post max/min TEST PASSED"]]).forEach((r, i) => {
  const y = 1.3 + i * 1.25;
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 8.0, y, w: 4.75, h: 1.05, rectRadius: 0.08, fill: { color: C.background1 }, line: { type: "none" }, objectName: "result " + r[0] });
  s.addText(r[0], { x: 8.2, y: y + 0.08, w: 4.4, h: 0.38, fontSize: 15, bold: true, color: C.accent1, margin: 0, isTextBox: true });
  s.addText(r[1], { x: 8.2, y: y + 0.48, w: 4.4, h: 0.45, fontSize: 13, color: C.text1, margin: 0, isTextBox: true });
});
s.addText(MODE === "FE" ? "개선 과제: I/O 예산을 SoC 실제 값으로 재설정 · 조합 출력(o_rdata) 레지스터화 검토 · 커버리지 기반 검증 확장" : "개선 과제: 지연 셀 허용 시 Hold 버퍼 감축 · I/O 예산을 SoC 실제 값으로 재설정 · Voltus IR-drop 분석", { x: MX, y: 6.3, w: 12.1, h: 0.5, fontSize: 13, color: C.accent5, margin: 0, isTextBox: true });

(async () => {
  await pres.writeFile({ fileName: OUT });
  await applyTheme(OUT, THEME);
  console.log("written", OUT);
})();
