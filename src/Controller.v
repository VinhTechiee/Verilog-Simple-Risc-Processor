module controller (
    input clk,
    input rst,
    input [2:0] opcode,
    input zero,
    output reg sel,
    output reg rd,
    output reg ld_ir,
    output reg halt,
    output reg inc_pc,
    output reg ld_ac,
    output reg ld_pc,
    output reg wr,
    output reg data_e

);
  // 1. TODO: Define state parameters for the 8-state FSM
  // 2. TODO: Define opcode parameters for the 8 instructions
  // 3. TODO: Declare a state register
  // 4. TODO: Implement a sequential logic block for FSM state transitions (triggered by posedge clk)
  // 5. TODO: Implement synchronous active-high reset to set the initial state
  // 6. TODO: Implement combinational logic to determine output control signals based on the current state and opcode
  // 7. TODO: Ensure all output signals are assigned a default value to prevent latches


  localparam INST_ADDR=3'd0, INST_FETCH=3'd1, INST_LOAD=3'd2,
               IDLE=3'd3, OP_ADDR=3'd4, OP_FETCH=3'd5,
               ALU_OP=3'd6, STORE=3'd7;

  reg [2:0] state;
  wire aluop = (opcode == 3'b010) || (opcode == 3'b011) || (opcode == 3'b100) || (opcode == 3'b101);

  // State register
  always @(posedge clk) begin
    if (rst) state <= INST_ADDR;
    else state <= (state == STORE) ? INST_ADDR : state + 1;
  end

  // Output logic (combinational)
  always @(*) begin
    {sel, rd, ld_ir, halt, inc_pc, ld_ac, ld_pc, wr, data_e} = 9'b0;

    if (rst) begin
      sel = 1;
    end else begin
      case (state)
        INST_ADDR:  sel = 1;
        INST_FETCH: {sel, rd} = 2'b11;
        INST_LOAD:  {sel, rd, ld_ir} = 3'b111;

        IDLE: begin
          {sel, rd, ld_ir} = 3'b111;
          if (opcode == 3'b000) halt = 1;
        end

        OP_ADDR: begin
          inc_pc = 1;
          if (opcode == 3'b000) halt = 1;
        end

        OP_FETCH: begin
          rd = aluop;
        end

        ALU_OP: begin
          rd = aluop;
          if (opcode == 3'b111) ld_pc = 1;
          if (opcode == 3'b110) data_e = 1;
          if (opcode == 3'b001 && zero) inc_pc = 1;
        end

        STORE: begin
          rd = aluop;
          ld_ac = aluop;
          if (opcode == 3'b111) ld_pc = 1;
          if (opcode == 3'b110) {wr, data_e} = 2'b11;
        end
      endcase
    end
  end

endmodule
