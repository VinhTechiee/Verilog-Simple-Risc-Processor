`timescale 1ns / 1ps

// ============================================================
// CPU2_tb.v — Top-Level Testbench for Integration (CPU)
// Covers execution of a comprehensive test program evaluating:
//   - LDA, ADD, STO sequence
//   - Conditional SKZ branching
//   - Unconditional JMP branching
//   - Bitwise XOR and AND operations
//   - HLT assertion
// ============================================================
module CPU2_tb;

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
  // Prints out whenever PC changes or an instruction cycle finishes (8 phases)
  task display_cpu_state;
    begin
      $display("time=%t | PC=%2d | State=%3b | Op=%3b | AC=%0d | Halt=%b", $time, uut.u_pc.pc_out,
               uut.u_controller.state, uut.opcode, uut.u_ac.ac_out, halt);
    end
  endtask

  // ── Load Program & Control Simulation ────────────────
  initial begin
    // 1. Load comprehensive test program into Memory
    // Program executes: (5 + 3), XOR 5, AND 3, tests SKZ/JMP
    uut.u_memory.mem_cells[0] = 8'hB4;  // LDA 20 -> AC = 5
    uut.u_memory.mem_cells[1] = 8'h55;  // ADD 21 -> AC = 8
    uut.u_memory.mem_cells[2] = 8'hD6;  // STO 22 -> Mem[22] = 8
    uut.u_memory.mem_cells[3] = 8'h20;  // SKZ    -> AC=8 (!=0) -> No jump
    uut.u_memory.mem_cells[4] = 8'hE6;  // JMP 6  -> PC jumps to 6
    uut.u_memory.mem_cells[5] = 8'h55;  // ADD 21 -> (Skipped due to JMP)
    uut.u_memory.mem_cells[6] = 8'h94;  // XOR 20 -> 8 XOR 5 = 13
    uut.u_memory.mem_cells[7] = 8'h75;  // AND 21 -> 13 AND 3 = 1
    uut.u_memory.mem_cells[8] = 8'hD7;  // STO 23 -> Mem[23] = 1
    uut.u_memory.mem_cells[9] = 8'hB8;  // LDA 24 -> AC = 0 (Data at 24 is 0)
    uut.u_memory.mem_cells[10] = 8'h20;  // SKZ    -> AC=0 -> Skip next instruction
    uut.u_memory.mem_cells[11] = 8'hD9;  // STO 25 -> (Skipped due to SKZ)
    uut.u_memory.mem_cells[12] = 8'h00;  // HLT    -> Halt

    // 2. Load operand data
    uut.u_memory.mem_cells[20] = 8'd5;
    uut.u_memory.mem_cells[21] = 8'd3;
    uut.u_memory.mem_cells[22] = 8'd0;
    uut.u_memory.mem_cells[23] = 8'd0;
    uut.u_memory.mem_cells[24] = 8'd0;

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
    $display("Mem[22] (Expected 8): %0d", uut.u_memory.mem_cells[22]);
    $display("Mem[23] (Expected 1): %0d", uut.u_memory.mem_cells[23]);

    if (uut.u_memory.mem_cells[22] == 8 && uut.u_memory.mem_cells[23] == 1)
      $display("--- TEST STATUS: PASS ---");
    else $display("--- TEST STATUS: FAIL ---");

    $finish;
  end

  // Safety Timeout
  initial #10000 $finish;

endmodule
