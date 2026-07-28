`timescale 1ns / 1ps

// ============================================================
// CPU_all_opcode_tb.v
//
// Compact regression test for all original CPU opcodes:
//
//   000 HLT
//   001 SKZ
//   010 ADD
//   011 AND
//   100 XOR
//   101 LDA
//   110 STO
//   111 JMP
//
// This testbench prints only one final PASS or FAIL line.
// ============================================================

module CPU_all_opcode_tb;

  reg clk;
  reg rst;

  wire halt;

  integer cycles;
  integer errors;
  integer i;

  // ------------------------------------------------------------
  // Device under test
  // ------------------------------------------------------------
  CPU dut (
      .clk (clk),
      .rst (rst),
      .halt(halt)
  );

  // ------------------------------------------------------------
  // Clock: 10 ns period
  // ------------------------------------------------------------
  initial begin
    clk = 1'b0;
  end

  always #5 clk = ~clk;

  // ------------------------------------------------------------
  // Program and data initialization
  // ------------------------------------------------------------
  initial begin
    rst    = 1'b1;
    cycles = 0;
    errors = 0;

    // Clear all memory locations.
    for (i = 0; i < 32; i = i + 1) begin
      dut.u_memory.mem_cells[i] = 8'h00;
    end

    // ----------------------------------------------------------
    // Program
    //
    //  0: LDA 20       AC = 0F
    //  1: AND 21       AC = 03
    //  2: XOR 22       AC = F3
    //  3: ADD 23       AC = F8
    //  4: STO 24       MEM[24] = F8
    //  5: LDA 25       AC = 00
    //  6: SKZ          skip address 7
    //  7: LDA 26       must not execute
    //  8: JMP 10       skip address 9
    //  9: LDA 27       must not execute
    // 10: HLT
    // ----------------------------------------------------------

    dut.u_memory.mem_cells[0]  = 8'hB4; // LDA 20
    dut.u_memory.mem_cells[1]  = 8'h75; // AND 21
    dut.u_memory.mem_cells[2]  = 8'h96; // XOR 22
    dut.u_memory.mem_cells[3]  = 8'h57; // ADD 23
    dut.u_memory.mem_cells[4]  = 8'hD8; // STO 24
    dut.u_memory.mem_cells[5]  = 8'hB9; // LDA 25
    dut.u_memory.mem_cells[6]  = 8'h20; // SKZ
    dut.u_memory.mem_cells[7]  = 8'hBA; // LDA 26, skipped
    dut.u_memory.mem_cells[8]  = 8'hEA; // JMP 10
    dut.u_memory.mem_cells[9]  = 8'hBB; // LDA 27, skipped
    dut.u_memory.mem_cells[10] = 8'h00; // HLT

    // ----------------------------------------------------------
    // Data
    // ----------------------------------------------------------
    dut.u_memory.mem_cells[20] = 8'h0F;
    dut.u_memory.mem_cells[21] = 8'h03;
    dut.u_memory.mem_cells[22] = 8'hF0;
    dut.u_memory.mem_cells[23] = 8'h05;
    dut.u_memory.mem_cells[24] = 8'h00;
    dut.u_memory.mem_cells[25] = 8'h00;
    dut.u_memory.mem_cells[26] = 8'hAA;
    dut.u_memory.mem_cells[27] = 8'hBB;

    // Keep reset asserted for four rising edges.
    repeat (4) @(posedge clk);
    #1 rst = 1'b0;
  end

  // ------------------------------------------------------------
  // Run CPU and perform final checks
  // ------------------------------------------------------------
  initial begin
    wait (rst === 1'b0);

    while ((halt !== 1'b1) && (cycles < 300)) begin
      @(posedge clk);
      cycles = cycles + 1;
    end

    // Allow final sequential updates to settle.
    #1;

    if (halt !== 1'b1) begin
      errors = errors + 1;
    end

    // ADD, AND and XOR result stored by STO.
    if (dut.u_memory.mem_cells[24] !== 8'hF8) begin
      errors = errors + 1;
    end

    // LDA 26 must be skipped by SKZ.
    // If it executed, AC would become AA.
    if (dut.u_memory.mem_cells[26] !== 8'hAA) begin
      errors = errors + 1;
    end

    // LDA 27 must be skipped by JMP.
    if (dut.u_memory.mem_cells[27] !== 8'hBB) begin
      errors = errors + 1;
    end

    // LDA 25 executes before SKZ, so final AC must remain zero.
    if (dut.u_ac.ac_out !== 8'h00) begin
      errors = errors + 1;
    end

    if (errors == 0) begin
      $display("PASS: all original opcodes");
    end
    else begin
      $display("FAIL: all original opcodes (%0d errors)", errors);
    end

    $finish;
  end

  // ------------------------------------------------------------
  // Absolute timeout protection
  // ------------------------------------------------------------
  initial begin
    #50000;
    $display("FAIL: timeout");
    $finish;
  end

endmodule