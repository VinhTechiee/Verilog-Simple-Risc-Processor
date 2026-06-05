`timescale 1ns / 1ps

// ============================================================
// CPU_tb.v — Top-Level Testbench for Integration (CPU)
// Covers execution of a basic test program from the README:
//   - LDA 20
//   - ADD 21
//   - STO 22
//   - HLT
// ============================================================
module CPU_tb;

  // ── Signals ─────────────────────────────────────────
  reg  clk;
  reg  rst;
  wire halt;

  // ── DUT instantiation ────────────────────────────────
  CPU uut (
      .clk (clk),
      .rst (rst),
      .halt(halt)
  );

  // ── Clock: 10 ns period ──────────────────────────────
  initial clk = 0;
  always #5 clk = ~clk;

  // ── Task: display CPU state ──────────────────────────
  task display_cpu_state;
    begin
      $display("time=%t | PC=%2d | State=%3b | Op=%3b | AC=%0d | Halt=%b", $time,
               uut.pc_unit.pc_out, uut.control_unit.state, uut.opcode, uut.ac_unit.ac_out, halt);
    end
  endtask

  // ── Load Program & Control Simulation ────────────────
  initial begin
    // 1. Load specific test program from README
    // LDA 20, ADD 21, STO 22, HLT
    uut.mem_unit.mem[0] = 8'hB4;  // LDA 20 (Opcode 101, Operand 10100)
    uut.mem_unit.mem[1] = 8'h55;  // ADD 21 (Opcode 010, Operand 10101)
    uut.mem_unit.mem[2] = 8'hD6;  // STO 22 (Opcode 110, Operand 10110)
    uut.mem_unit.mem[3] = 8'h00;  // HLT    (Opcode 000, Operand 00000)

    // 2. Load input data according to README
    uut.mem_unit.mem[20] = 8'd5;
    uut.mem_unit.mem[21] = 8'd3;
    uut.mem_unit.mem[22] = 8'd0;  // Location to store result

    // 3. Reset system
    rst = 1;
    repeat (2) @(posedge clk);
    #1;
    rst = 0;

    $display("--- CPU INTEGRATION TEST STARTED ---");
  end

  // Monitor state at each positive clock edge
  always @(posedge clk) begin
    if (!rst) display_cpu_state();
  end

  // Final result check after HLT
  initial begin
    wait (halt === 1'b1);
    repeat (2) @(posedge clk);

    $display("--- FINAL RESULT CHECK ---");
    $display("Mem[22] (Expected 8): %0d", uut.mem_unit.mem[22]);

    if (uut.mem_unit.mem[22] == 8) $display("--- TEST STATUS: PASS ---");
    else $display("--- TEST STATUS: FAIL ---");

    $finish;
  end

  // Safety Timeout
  initial #10000 $finish;

endmodule
