module alu (
    input [31:0] inA,
    input [31:0] inB, 
    input [2:0] opcode,  
    output reg [31:0] alu_out,
    output zero 
);
    // 1. TODO: Implement combinational logic to set the zero flag if inA is 0
    // 2. TODO: Implement combinational logic to perform arithmetic and logic operations based on the opcode
    // 3. TODO: Define operations for HLT, SKZ, ADD, AND, XOR, LDA, STO, JMP instructions
    // 4. TODO: Assign the result to alu_out

endmodule
