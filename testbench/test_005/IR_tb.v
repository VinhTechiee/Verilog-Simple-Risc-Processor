`timescale 1ns / 1ps

// ============================================================
// IR_tb.v — Testbench for Instruction Register (IR)
// Covers 7 scenarios described in the project spec:
//   TC1: System Reset
//   TC2: Load Instruction
//   TC3: Hold Value
//   TC4: Extract Opcode and Operand
//   TC5: Reset Priority
//   TC6: Bus Noise Immunity
//   TC7: High-bit Masking
// ============================================================

module IR_tb;
  // ── Signals ─────────────────────────────────────────
  reg clk;
  reg rst;
  reg ld_ir;
  reg [31:0] data_in;

  wire [2:0] opcode;
  wire [4:0] operand;

  // ── DUT instantiation ────────────────────────────────
  instruction_register uut (
      .clk(clk),
      .rst(rst),
      .ld_ir(ld_ir),
      .data_in(data_in),
      .opcode(opcode),
      .operand(operand)
  );

  // ── Clock: 10 ns period ──────────────────────────────
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // ── Task: tick one clock and display state ───────────
  task display_state;
    input [8*5:1] tc_name;
    begin
      @(posedge clk);
      #1;  // Wait after posedge for data to update
      $display("%s | rst=%b | ld_ir=%b | data_in=0x%08X | opcode=%b | operand=%b", tc_name, rst,
               ld_ir, data_in, opcode, operand);
    end
  endtask

  initial begin
    // Init
    rst = 1;
    ld_ir = 0;
    data_in = 32'd0;
    #1;
    // ── TC1: System Reset ────────────────────────────
    $display("--- TC1: System Reset ---");
    display_state("TC1.1");  // Expect opcode=0, operand=0

    rst = 0;  // De-assert reset

    // ── TC2: Load Instruction ────────────────────────
    $display("--- TC2: Load Instruction ---");
    ld_ir   = 1;
    // Instruction 1: Opcode = 101 (LDA), Operand = 10101
    // Combined: [7:5] = 101, [4:0] = 10101 -> 1011_0101 = 0xB5
    data_in = 32'h000000B5;
    display_state("TC2.1");  // Expect: opcode=101, operand=10101

    // Instruction 2: Opcode = 010 (ADD), Operand = 00011
    // Combined: [7:5] = 010, [4:0] = 00011 -> 0100_0011 = 0x43
    data_in = 32'h00000043;
    display_state("TC2.2");  // Expect: opcode=010, operand=00011

    // ── TC3: Hold Value ──────────────────────────────
    $display("--- TC3: Hold Value ---");
    ld_ir   = 0;  // De-assert load instruction signal
    data_in = 32'hFFFFFFFF;  // Change data on bus
    display_state("TC3.1");  // Expect: opcode=010, operand=00011 (holds value)
    display_state("TC3.2");  // Expect: opcode=010, operand=00011

    // ── TC4: Extract Opcode and Operand ──────────────
    $display("--- TC4: Extract Opcode and Operand ---");
    // Instruction 3: Opcode = 111 (JMP), Operand = 11111
    // Combined: [7:5] = 111, [4:0] = 11111 -> 1111_1111 = 0xFF
    // Pad upper bits with arbitrary pattern (e.g., 0xDEADBE)
    ld_ir   = 1;
    data_in = 32'hDEADBEFF;
    display_state("TC4.1");  // Kỳ vọng: opcode=111, operand=11111

    // Instruction 4: Opcode = 000 (HLT), Operand = 00000
    data_in = 32'h12345600;
    display_state("TC4.2");  // Expect: opcode=000, operand=00000

    // ── TC5: Reset Priority ──────────────────────────
    $display("--- TC5: Reset Priority ---");
    ld_ir   = 1;
    data_in = 32'hFFFFFFFF;  // Attempt to load all 1s
    rst     = 1;  // But assert reset simultaneously
    display_state("TC5.1");  // Expect: opcode=000, operand=00000
    rst = 0;
    display_state(
        "TC5.2");  // After reset is de-asserted, FFFF data is loaded (opcode=111, op=11111)

    // ── TC6: Bus Noise Immunity ──────────────────────
    // Change data_in continuously when ld_ir = 0
    $display("--- TC6: Bus Noise Immunity ---");
    ld_ir   = 0;
    data_in = 32'hAAAAAAAA;
    #2;
    data_in = 32'h55555555;
    #2;
    data_in = 32'h12345678;
    display_state("TC6.1");  // Expect: holds value from TC5.2 (111, 11111)

    // ── TC7: High-bit Masking ────────────────────────
    // Ensure only bits [7:0] affect output, others are ignored
    $display("--- TC7: High-bit Masking ---");
    ld_ir   = 1;
    // Load ADD (010) Operand (01010) with high bits 0xABCDEF
    data_in = 32'hABCDEF4A;  // 4A = 010_01010
    display_state("TC7.1");  // Expect: opcode=010, operand=01010

    // Load LDA (101) Operand (11111) with high bits 0x000000
    data_in = 32'h000000BF;  // BF = 101_11111
    display_state("TC7.2");  // Expect: opcode=101, operand=11111

    $display("--- DONE ---");
    $finish;
  end
endmodule
