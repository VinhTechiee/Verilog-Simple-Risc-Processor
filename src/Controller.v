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
  localparam  INST_ADDR=3'd0,
              INST_FETCH=3'd1, 
              INST_LOAD=3'd2,
              IDLE=3'd3, 
              OP_ADDR=3'd4, 
              OP_FETCH=3'd5,
              ALU_OP=3'd6, 
              STORE=3'd7;

  // Opcodes
  localparam HLT = 3'b000,
             SKZ = 3'b001,
             ADD = 3'b010,
             AND = 3'b011,
             XOR = 3'b100,
             LDA = 3'b101,
             STO = 3'b110,
             JMP = 3'b111;

  reg [2:0] state;
  reg halted;

  wire aluop;
  assign aluop = (opcode == ADD) ||
                 (opcode == AND) ||
                 (opcode == XOR) ||
                 (opcode == LDA);

  // State register
  always @(posedge clk) begin
    if (rst) begin
      state <= INST_ADDR;
      halted <= 1'b0;
  end else if (halted) begin
      state  <= state;
      halted <= 1'b1;
    end else begin
      if ((state == OP_ADDR) && (opcode == HLT)) begin
        state  <= OP_ADDR;
        halted <= 1'b1;
      end else begin
        state <= (state == STORE) ? INST_ADDR : state + 3'd1;
      end
    end
  end

  // Output logic (combinational)
  always @(*) begin
    // Default values
    sel    = 1'b0;
    rd     = 1'b0;
    ld_ir  = 1'b0;
    halt   = 1'b0;
    inc_pc = 1'b0;
    ld_ac  = 1'b0;
    ld_pc  = 1'b0;
    wr     = 1'b0;
    data_e = 1'b0;

    if (rst) begin
      sel = 1'b1;
    end else if (halted) begin
      halt = 1'b1;
    end else begin
      case (state)

        INST_ADDR: begin
          sel = 1'b1;
        end

        INST_FETCH: begin
          sel = 1'b1;
          rd  = 1'b1;
        end

        INST_LOAD: begin
          sel   = 1'b1;
          rd    = 1'b1;
          ld_ir = 1'b1;
        end

        IDLE: begin
          sel   = 1'b1;
          rd    = 1'b1;
          ld_ir = 1'b1;
        end

        OP_ADDR: begin
          inc_pc = 1'b1;

          if (opcode == HLT) begin
            halt = 1'b1;
          end
        end

        OP_FETCH: begin
          rd = aluop;
        end

        ALU_OP: begin
          rd = aluop;

          if (opcode == SKZ && zero) begin
            inc_pc = 1'b1;
          end

          if (opcode == JMP) begin
            ld_pc = 1'b1;
          end

          if (opcode == STO) begin
            data_e = 1'b1;
          end
        end

        STORE: begin
          rd    = aluop;
          ld_ac = aluop;

          if (opcode == JMP) begin
            ld_pc = 1'b1;
          end

          if (opcode == STO) begin
            wr     = 1'b1;
            data_e = 1'b1;
          end
        end

        default: begin
          sel    = 1'b0;
          rd     = 1'b0;
          ld_ir  = 1'b0;
          halt   = 1'b0;
          inc_pc = 1'b0;
          ld_ac  = 1'b0;
          ld_pc  = 1'b0;
          wr     = 1'b0;
          data_e = 1'b0;
        end

      endcase
    end
  end

endmodule
