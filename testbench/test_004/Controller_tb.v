`timescale 1ns / 1ps

// ============================================================
// Controller_tb.v — Testbench for Controller
// Covers:
//   TC1: Reset
//   TC2: Fetch phase
//   TC3: ADD execution
//   TC4: STO execution
//   TC5: JMP execution
//   TC6: HLT stable halt
//   TC7: SKZ with zero=0 and zero=1
// ============================================================
module Controller_tb;

  reg       clk;
  reg       rst;
  reg [2:0] opcode;
  reg       zero;

  wire sel, rd, ld_ir, halt, inc_pc, ld_ac, ld_pc, wr, data_e;

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

  initial clk = 0;
  always #5 clk = ~clk;

  task tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task reset_controller;
    begin
      rst = 1;
      repeat (2) @(posedge clk);
      #1;
      rst = 0;
    end
  endtask

  task display_state;
    input [8*14:1] state_name;
    begin
      $display(
          "%s | state=%3b opcode=%3b zero=%b | sel=%b rd=%b ld_ir=%b halt=%b inc_pc=%b ld_ac=%b ld_pc=%b wr=%b data_e=%b",
          state_name, uut.state, opcode, zero, sel, rd, ld_ir, halt, inc_pc, ld_ac, ld_pc, wr,
          data_e);
    end
  endtask

  initial begin
    opcode = 3'b000;
    zero   = 1'b0;
    rst    = 1'b1;

    reset_controller();

    $display("--- TC1: System Reset / INST_ADDR ---");
    display_state("0:INST_ADDR   ");

    $display("--- TC2: Fetch Phase ---");
    opcode = 3'b010;  // ADD
    display_state("0:INST_ADDR   ");
    tick();
    display_state("1:INST_FETCH  ");
    tick();
    display_state("2:INST_LOAD   ");
    tick();
    display_state("3:IDLE        ");

    $display("--- TC3: Execution Phase (ADD) ---");
    tick();
    display_state("4:OP_ADDR     ");
    tick();
    display_state("5:OP_FETCH    ");
    tick();
    display_state("6:ALU_OP      ");
    tick();
    display_state("7:STORE       ");
    tick();
    display_state("0:INST_ADDR   ");

    $display("--- TC4: Execution Phase (STO) ---");
    reset_controller();
    opcode = 3'b110;  // STO
    tick();
    tick();
    tick();
    tick();
    display_state("4:OP_ADDR     ");
    tick();
    display_state("5:OP_FETCH    ");
    tick();
    display_state("6:ALU_OP      ");
    tick();
    display_state("7:STORE       ");

    $display("--- TC5: Execution Phase (JMP) ---");
    reset_controller();
    opcode = 3'b111;  // JMP
    tick();
    tick();
    tick();
    tick();
    display_state("4:OP_ADDR     ");
    tick();
    display_state("5:OP_FETCH    ");
    tick();
    display_state("6:ALU_OP      ");
    tick();
    display_state("7:STORE       ");

    $display("--- TC6: Execution Phase (HLT, stable halt) ---");
    reset_controller();
    opcode = 3'b000;  // HLT
    tick();
    tick();
    tick();
    tick();
    display_state("4:OP_ADDR/HLT ");
    tick();
    display_state("HOLD_HALT_1   ");
    tick();
    display_state("HOLD_HALT_2   ");

    $display("--- TC7.1: SKZ zero=0, no skip ---");
    reset_controller();
    opcode = 3'b001;  // SKZ
    zero   = 1'b0;
    tick();
    tick();
    tick();
    tick();
    display_state("4:OP_ADDR     ");
    tick();
    display_state("5:OP_FETCH    ");
    tick();
    display_state("6:ALU_OP      ");  // inc_pc should be 0
    tick();
    display_state("7:STORE       ");

    $display("--- TC7.2: SKZ zero=1, skip next instruction ---");
    reset_controller();
    opcode = 3'b001;  // SKZ
    zero   = 1'b1;
    tick();
    tick();
    tick();
    tick();
    display_state("4:OP_ADDR     ");
    tick();
    display_state("5:OP_FETCH    ");
    tick();
    display_state("6:ALU_OP      ");  // inc_pc should be 1
    tick();
    display_state("7:STORE       ");

    $display("--- DONE ---");
    $finish;
  end

endmodule
