module instruction_register (
    input         clk,
    input         rst,
    input         ld_ir,
    input  [31:0] data_in,
    output [ 2:0] opcode,
    output [ 4:0] operand
);

  // 1. Declare an internal register to store the instruction data
  reg [7:0] ir_reg;

  // 2. Implement a sequential logic block triggered by the positive edge of the clock
  always @(posedge clk) begin
    // 3. Implement synchronous active-high reset to clear the register
    if (rst) begin
      ir_reg <= 8'b00000000;
    end  // 4. Implement logic to load data_in into the register when ld_ir is active
    else if (ld_ir) begin
      ir_reg <= data_in[7:0];
    end
  end

  // 5. Implement combinational logic to extract the 3-bit opcode from the stored instruction
  assign opcode  = ir_reg[7:5];

  // 6. Implement combinational logic to extract the 5-bit operand from the stored instruction
  assign operand = ir_reg[4:0];

endmodule
