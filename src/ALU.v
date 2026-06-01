// 1. TODO: Implement combinational logic to set the zero flag if inA is 0
// 2. TODO: Implement combinational logic to perform arithmetic and logic operations based on the opcode
// 3. TODO: Define operations for HLT, SKZ, ADD, AND, XOR, LDA, STO, JMP instructions
// 4. TODO: Assign the result to alu_out
module ALU (
    input [2:0] opcode,
    input [7:0] inA,
    input [7:0] inB,

    output reg [7:0] alu_out,
    output zero
);
  always @(*) begin
    case (opcode)
      3'b000:  alu_out = inA;
      3'b001:  alu_out = inA;
      3'b010:  alu_out = inA + inB;
      3'b011:  alu_out = inA & inB;
      3'b100:  alu_out = inA ^ inB;
      3'b101:  alu_out = inB;
      3'b110:  alu_out = inA;
      3'b111:  alu_out = inA;
      default: alu_out = 8'b00000000;
    endcase
  end
  assign zero = (inA == 8'b00000000);

endmodule
