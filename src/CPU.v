module CPU (
    input  clk,
    input  rst,
    output halt
);


  // =========================
  // Internal wires
  // =========================

  // Control signals
  wire sel;
  wire rd;
  wire ld_ir;
  wire inc_pc;
  wire ld_ac;
  wire ld_pc;
  wire wr;
  wire data_e;

  // Datapath signals
  wire [4:0] pc_out;
  wire [4:0] operand;
  wire [4:0] mem_addr;

  wire [2:0] opcode;

  wire [7:0] data_bus;
  wire [7:0] ac_out;
  wire [7:0] alu_out;

  wire zero;

  // =========================
  // Data bus tri-state logic
  // =========================
  // For STO instruction:
  // CPU drives AC value onto data_bus when data_e = 1.
  // Otherwise, CPU releases the bus and Memory can drive it during read.
  assign data_bus = (data_e && !rd) ? ac_out : 8'hZZ;

  // =========================
  // Program Counter
  // =========================
  PC u_pc (
      .clk    (clk),
      .rst    (rst),
      .ld_pc  (ld_pc),
      .inc_pc (inc_pc),
      .data_in(operand),
      .pc_out (pc_out)
  );

  // =========================
  // Address MUX
  // sel = 1: use PC address for instruction fetch
  // sel = 0: use operand address for data access
  // =========================
  address_mux #(
      .WIDTH(5)
  ) u_address_mux (
      .pc_addr (pc_out),
      .ir_addr (operand),
      .sel     (sel),
      .addr_out(mem_addr)
  );

  // =========================
  // Memory
  // =========================
  Memory u_memory (
      .clk (clk),
      .rd  (rd),
      .wr  (wr),
      .addr(mem_addr),
      .data(data_bus)
  );

  // =========================
  // Instruction Register
  // instruction format:
  // [7:5] opcode
  // [4:0] operand address
  // =========================
  instruction_register u_ir (
      .clk    (clk),
      .rst    (rst),
      .ld_ir  (ld_ir),
      .data_in(data_bus),
      .opcode (opcode),
      .operand(operand)
  );

  // =========================
  // Accumulator
  // =========================
  accumulator u_ac (
      .clk    (clk),
      .rst    (rst),
      .data_in(alu_out),
      .ld_ac  (ld_ac),
      .ac_out (ac_out)
  );

  // =========================
  // ALU
  // inA = Accumulator
  // inB = Memory data bus
  // =========================
  ALU u_alu (
      .opcode (opcode),
      .inA    (ac_out),
      .inB    (data_bus),
      .alu_out(alu_out),
      .zero   (zero)
  );

  // =========================
  // Controller
  // =========================
  controller u_controller (
      .clk   (clk),
      .rst   (rst),
      .opcode(opcode),
      .zero  (zero),

      .sel   (sel),
      .rd    (rd),
      .ld_ir (ld_ir),
      .halt  (halt),
      .inc_pc(inc_pc),
      .ld_ac (ld_ac),
      .ld_pc (ld_pc),
      .wr    (wr),
      .data_e(data_e)
  );

endmodule
