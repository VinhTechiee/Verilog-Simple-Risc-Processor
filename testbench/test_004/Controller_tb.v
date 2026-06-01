`timescale 1ns / 1ps

// ============================================================
// Controller_tb.v — Testbench for Controller
// Covers 6 scenarios:
//   TC1: System Reset
//   TC2 & TC3: Fetch Phase
//   TC4: Execution Phase (ADD, STO, JMP, HLT)
//   TC5: Conditional Jump (SKZ)
//   TC6: Sync Signals (Async Reset check)
// ============================================================
module Controller_tb;

  // ── Signals ─────────────────────────────────────────
  reg       clk;
  reg       rst;
  reg [2:0] opcode;
  reg       zero;

  wire sel, rd, ld_ir, halt, inc_pc, ld_ac, ld_pc, wr, data_e;

  // ── DUT instantiation ────────────────────────────────
  controller uut (
      .clk   (clk),
      .rst   (rst),
      .opcode(opcode),
      .zero  (zero),
      .sel   (sel),
      .rd    (rd),
      .ld_ir (ld_ir),
      .halt  (halt),
      .inc_pc(inc_pc),
      .ld_ac (ld_ac),
      .ld_pc (ld_pc),
      .wr    (wr),
      .data_e(data_e)
  );

  // ── Clock: 10 ns period ──────────────────────────────
  initial clk = 0;
  always #5 clk = ~clk;

  // ── Task: tick one clock cycle ───────────────────────
  task tick;
    begin
      @(posedge clk);
      #1;  // Wait for output signals to stabilize
    end
  endtask

  // ── Task: display state ──────────────────────────────
  task display_state;
    input [8*12:1] state_name;
    begin
      $display(
          "%s | opcode=%b zero=%b | sel=%b rd=%b ld_ir=%b halt=%b inc_pc=%b ld_ac=%b ld_pc=%b wr=%b data_e=%b",
          state_name, opcode, zero, sel, rd, ld_ir, halt, inc_pc, ld_ac, ld_pc, wr, data_e);
    end
  endtask

  initial begin
    // Init
    rst = 1;
    opcode = 3'b000;
    zero = 0;
    repeat (2) @(posedge clk);
    #1;

    // ── TC1: System Reset ────────────────────────────
    $display("--- TC1: System Reset ---");
    display_state("Reset       ");

    // De-assert reset
    rst = 0;

    // ── TC2 & TC3: Fetch Phase ───────────────────────
    $display("--- TC2 & TC3: Fetch Phase ---");
    opcode = 3'b010;
    display_state("0:INST_ADDR ");
    tick();  // -> 1
    display_state("1:INST_FETCH");
    tick();  // -> 2
    display_state("2:INST_LOAD ");
    tick();  // -> 3
    display_state("3:IDLE      ");
    tick();  // -> 4

    // ── TC4: Execution Phase (ADD) ───────────────────
    $display("--- TC4: Execution Phase (ADD) ---");
    display_state("4:OP_ADDR   ");
    tick();  // -> 5
    display_state("5:OP_FETCH  ");
    tick();  // -> 6
    display_state("6:ALU_OP    ");
    tick();  // -> 7
    display_state("7:STORE     ");
    tick();  // -> 0

    // ── TC4: Execution Phase (STO) ───────────────────
    $display("--- TC4: Execution Phase (STO) ---");
    rst = 1;
    #10;
    rst = 0;
    opcode = 3'b110;  // STO
    tick();
    tick();
    tick();
    tick();  // Skip fetch phase
    display_state("4:OP_ADDR   ");
    tick();
    display_state("5:OP_FETCH  ");
    tick();
    display_state("6:ALU_OP    ");
    tick();
    display_state("7:STORE     ");
    tick();  // -> 0

    // ── TC4: Execution Phase (JMP) ───────────────────
    $display("--- TC4: Execution Phase (JMP) ---");
    rst = 1;
    #10;
    rst = 0;
    opcode = 3'b111;  // JMP
    tick();
    tick();
    tick();
    tick();
    display_state("4:OP_ADDR   ");
    tick();
    display_state("5:OP_FETCH  ");
    tick();
    display_state("6:ALU_OP    ");
    tick();
    display_state("7:STORE     ");
    tick();  // -> 0

    // ── TC4: Execution Phase (HLT) ───────────────────
    $display("--- TC4: Execution Phase (HLT) ---");
    rst = 1;
    #10;
    rst = 0;
    opcode = 3'b000;  // HLT
    tick();
    tick();
    tick();
    tick();
    display_state("4:OP_ADDR   ");
    tick();
    display_state("5:OP_FETCH  ");
    tick();
    display_state("6:ALU_OP    ");
    tick();
    display_state("7:STORE     ");
    tick();  // -> 0

    // ── TC5: Conditional Jump (SKZ) ──────────────────
    $display("--- TC5: Conditional Jump (SKZ) ---");
    rst = 1;
    #10;
    rst    = 0;
    opcode = 3'b001;  // SKZ
    zero   = 0;  // No jump
    tick();
    tick();
    tick();
    tick();
    display_state("4:OP_ADDR   ");
    tick();
    display_state("5:OP_FETCH  ");
    tick();
    $display("   [zero=0] at ALU_OP:");
    display_state("6:ALU_OP    ");  // inc_pc = 0
    tick();
    display_state("7:STORE     ");
    tick();  // -> 0

    rst = 1;
    #10;
    rst    = 0;
    opcode = 3'b001;  // SKZ
    zero   = 1;  // Jump occurs
    tick();
    tick();
    tick();
    tick();
    display_state("4:OP_ADDR   ");
    tick();
    display_state("5:OP_FETCH  ");
    tick();
    $display("   [zero=1] at ALU_OP:");
    display_state("6:ALU_OP    ");  // inc_pc = 1
    tick();
    display_state("7:STORE     ");

    // ── TC6: Sync Signals (Async Reset check) ────────
    $display("--- TC6: Sync Signals (Async Reset check) ---");
    rst = 1;
    #2;
    display_state("Reset Async ");

    $display("--- DONE ---");
    $finish;
  end
endmodule
