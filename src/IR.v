module instruction_register (
    input        clk,
    input        rst,
    input        ld_ir,
    input  [7:0] data_in,
    output [2:0] opcode,
    output [4:0] operand
);

  reg [7:0] ir_reg;

  always @(posedge clk) begin
    if (rst) begin
      ir_reg <= 8'b00000000;
    end else if (ld_ir) begin
      ir_reg <= data_in[7:0];
    end
  end

  assign opcode  = ir_reg[7:5];

  assign operand = ir_reg[4:0];

endmodule
