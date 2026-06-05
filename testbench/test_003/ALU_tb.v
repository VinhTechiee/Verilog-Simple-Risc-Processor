`timescale 1ns / 1ps

// ============================================================
// ALU_tb.v — Testbench for Arithmetic Logic Unit (ALU)
// Covers 7 scenarios:
//   TC1: Zero Status Flag
//   TC2: Arithmetic & Logic
//   TC3: Transfer Operations
//   TC4: Combinational Property
//   TC5: Boundary Cases
//   TC6: Complex Bitwise Logic
//   TC7: Zero Flag Independence
// ============================================================
`timescale 1ns/1ps

module ALU_tb;

  reg  [7:0] inA;
  reg  [7:0] inB;
  reg  [2:0] opcode;

  wire [7:0] alu_out;
  wire       zero;

  // DUT
  ALU uut (
      .inA(inA),
      .inB(inB),
      .opcode(opcode),
      .alu_out(alu_out),
      .zero(zero)
  );
  
  task display_state;
    input [8*6:1] tc_name;
    begin
      #1;
      $display("%s | opcode=%b | inA=%0d | inB=%0d | zero=%b | alu_out=%0d",
               tc_name, opcode, inA, inB, zero, alu_out);
    end
  endtask

  initial begin

    // Initialize
    inA = 0;
    inB = 0;
    opcode = 3'b000;
    #10;

    // TC1: Zero Status Flag
    $display("\n--- TC1: Zero Status Flag ---");

    inA = 8'd0;
    display_state("TC1.1");   // zero = 1

    inA = 8'd50;
    display_state("TC1.2");   // zero = 0

    // TC2: Arithmetic & Logic Operations
    $display("\n--- TC2: Arithmetic & Logic ---");

    inA = 8'd100;
    inB = 8'd25;

    // ADD
    opcode = 3'b010;
    display_state("ADD");     // 125

    // AND
    opcode = 3'b011;
    display_state("AND");     // 0

    // XOR
    opcode = 3'b100;
    display_state("XOR");     // 125

    // LDA
    opcode = 3'b101;
    display_state("LDA");     // 25

    
    // TC3: Transfer Instructions
    $display("\n--- TC3: HLT / SKZ / STO / JMP ---");

    inA = 8'd200;
    inB = 8'd100;

    // HLT
    opcode = 3'b000;
    display_state("HLT");     // 200

    // SKZ
    opcode = 3'b001;
    display_state("SKZ");     // 200

    // STO
    opcode = 3'b110;
    display_state("STO");     // 200

    // JMP
    opcode = 3'b111;
    display_state("JMP");     // 200

    
    // TC4: Combinational Property
    $display("\n--- TC4: Combinational Property ---");

    opcode = 3'b010; // ADD

    inA = 8'd10;
    inB = 8'd20;
    #1;

    $display("TC4.1 | alu_out=%0d (Expected 30)", alu_out);

    // Change inputs immediately
    inA = 8'd50;
    inB = 8'd10;
    #1;

    $display("TC4.2 | alu_out=%0d (Expected 60)", alu_out);

    // TC5: Boundary Cases
    $display("\n--- TC5: Boundary Cases ---");

    opcode = 3'b010; // ADD

    inA = 8'hFF;
    inB = 8'h01;
    display_state("OVF1");    // Expect 0

    inA = 8'h7F;
    inB = 8'h7F;
    display_state("OVF2");    // Expect 254

    // TC6: Complex Bitwise Logic
    $display("\n--- TC6: Complex Bitwise Logic ---");

    inA = 8'hAA; // 10101010
    inB = 8'h55; // 01010101

    opcode = 3'b011;
    display_state("AND_C");   // 0

    opcode = 3'b100;
    display_state("XOR_C");   // 255

    
    // TC7: Zero Flag Independence
    $display("\n--- TC7: Zero Flag Independence ---");

    opcode = 3'b101; // LDA

    inA = 8'd0;
    inB = 8'd100;
    #1;
    $display("TC7.1 | zero=%b | alu_out=%0d", zero, alu_out);

    inA = 8'd1;
    inB = 8'd100;
    #1;
    $display("TC7.2 | zero=%b | alu_out=%0d", zero, alu_out);
    
    $display("\n--- ALL TESTS FINISHED ---");
    $finish;

  end

endmodule
