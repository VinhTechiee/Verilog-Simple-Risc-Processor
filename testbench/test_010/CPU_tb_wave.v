`timescale 1ns / 1ps

// ============================================================
// CPU_tb.v -- Waveform-heavy CPU integration testbench
//
// Purpose:
//   This testbench verifies all original CPU instructions and
//   generates a rich waveform for GTKWave.
//
// Waveform outputs:
//   - CPU_tb_wave.vcd
//   - CPU_tb_wave.shm, optional with +define+USE_SHM
//
// Instruction coverage:
//   HLT, SKZ, ADD, AND, XOR, LDA, STO, JMP
//
// Program:
//   00: LDA 24       AC = 5
//   01: ADD 25       AC = 8
//   02: STO 26       MEM[26] = 8
//   03: XOR 24       AC = 13
//   04: AND 25       AC = 1
//   05: STO 27       MEM[27] = 1
//   06: LDA 28       AC = 0
//   07: SKZ          zero -> skip instruction 08
//   08: STO 29       skipped, MEM[29] remains AA
//   09: LDA 25       AC = 3
//   10: SKZ          non-zero -> do not skip instruction 11
//   11: STO 30       MEM[30] = 3
//   12: JMP 14       skip instruction 13
//   13: STO 31       skipped, MEM[31] remains BB
//   14: LDA 26       AC = 8
//   15: ADD 27       AC = 9
//   16: STO 23       MEM[23] = 9
//   17: HLT          halt asserted
// ============================================================

module CPU_tb;

  // Set to 1 to print one trace row per clock cycle.
  // Keep at 0 for golden-output regression testing.
  localparam VERBOSE = 1'b0;

  // ------------------------------------------------------------
  // Testbench signals
  // ------------------------------------------------------------
  reg  clk;
  reg  rst;
  wire halt;

  integer cycle_count;
  integer errors;
  integer tests;
  integer i;

  // ------------------------------------------------------------
  // DUT
  // ------------------------------------------------------------
  CPU dut (
      .clk (clk),
      .rst (rst),
      .halt(halt)
  );

  // ------------------------------------------------------------
  // Clock: 10 ns period
  // ------------------------------------------------------------
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // ------------------------------------------------------------
  // Opcode and controller state names
  // ------------------------------------------------------------
  localparam [2:0] HLT = 3'b000;
  localparam [2:0] SKZ = 3'b001;
  localparam [2:0] ADD = 3'b010;
  localparam [2:0] AND = 3'b011;
  localparam [2:0] XOR = 3'b100;
  localparam [2:0] LDA = 3'b101;
  localparam [2:0] STO = 3'b110;
  localparam [2:0] JMP = 3'b111;

  localparam [2:0] INST_ADDR  = 3'd0;
  localparam [2:0] INST_FETCH = 3'd1;
  localparam [2:0] INST_LOAD  = 3'd2;
  localparam [2:0] IDLE       = 3'd3;
  localparam [2:0] OP_ADDR    = 3'd4;
  localparam [2:0] OP_FETCH   = 3'd5;
  localparam [2:0] ALU_OP     = 3'd6;
  localparam [2:0] STORE      = 3'd7;

  // ------------------------------------------------------------
  // Waveform aliases
  // ------------------------------------------------------------
  wire [4:0] wave_pc           = dut.u_pc.pc_out;
  wire [2:0] wave_state        = dut.u_controller.state;
  wire       wave_halted_latch = dut.u_controller.halted;

  wire [7:0] wave_ir_reg       = dut.u_ir.ir_reg;
  wire [2:0] wave_opcode       = dut.opcode;
  wire [4:0] wave_operand      = dut.operand;

  wire [4:0] wave_mem_addr     = dut.mem_addr;
  wire [7:0] wave_data_bus     = dut.data_bus;
  wire [7:0] wave_memory_out   = dut.u_memory.data_out;

  wire [7:0] wave_ac           = dut.u_ac.ac_out;
  wire [7:0] wave_alu_out      = dut.alu_out;
  wire       wave_zero         = dut.zero;

  wire       wave_sel          = dut.sel;
  wire       wave_rd           = dut.rd;
  wire       wave_ld_ir        = dut.ld_ir;
  wire       wave_inc_pc       = dut.inc_pc;
  wire       wave_ld_ac        = dut.ld_ac;
  wire       wave_ld_pc        = dut.ld_pc;
  wire       wave_wr           = dut.wr;
  wire       wave_data_e       = dut.data_e;

  // ------------------------------------------------------------
  // Derived waveform markers
  // ------------------------------------------------------------
  wire wave_is_fetch_phase =
      (wave_state == INST_ADDR)  ||
      (wave_state == INST_FETCH) ||
      (wave_state == INST_LOAD)  ||
      (wave_state == IDLE);

  wire wave_is_operand_phase =
      (wave_state == OP_ADDR) ||
      (wave_state == OP_FETCH);

  wire wave_is_execute_phase =
      (wave_state == ALU_OP);

  wire wave_is_store_phase =
      (wave_state == STORE);

  wire wave_aluop =
      (wave_opcode == ADD) ||
      (wave_opcode == AND) ||
      (wave_opcode == XOR) ||
      (wave_opcode == LDA);

  wire wave_skip_taken =
      (wave_state == ALU_OP) &&
      (wave_opcode == SKZ) &&
      wave_zero;

  wire wave_jump_taken =
      ((wave_state == ALU_OP) ||
       (wave_state == STORE)) &&
      (wave_opcode == JMP) &&
      wave_ld_pc;

  wire wave_store_taken =
      (wave_state == STORE) &&
      (wave_opcode == STO) &&
      wave_wr;

  wire wave_ac_load_event =
      (wave_state == STORE) &&
      wave_ld_ac;

  wire wave_mem_read_event =
      wave_rd && !wave_wr;

  wire wave_mem_write_event =
      wave_wr && !wave_rd;

  wire wave_exec_hlt = (wave_opcode == HLT);
  wire wave_exec_skz = (wave_opcode == SKZ);
  wire wave_exec_add = (wave_opcode == ADD);
  wire wave_exec_and = (wave_opcode == AND);
  wire wave_exec_xor = (wave_opcode == XOR);
  wire wave_exec_lda = (wave_opcode == LDA);
  wire wave_exec_sto = (wave_opcode == STO);
  wire wave_exec_jmp = (wave_opcode == JMP);

  // ------------------------------------------------------------
  // Memory aliases
  // ------------------------------------------------------------
  wire [7:0] mem_00 = dut.u_memory.mem_cells[0];
  wire [7:0] mem_01 = dut.u_memory.mem_cells[1];
  wire [7:0] mem_02 = dut.u_memory.mem_cells[2];
  wire [7:0] mem_03 = dut.u_memory.mem_cells[3];
  wire [7:0] mem_04 = dut.u_memory.mem_cells[4];
  wire [7:0] mem_05 = dut.u_memory.mem_cells[5];
  wire [7:0] mem_06 = dut.u_memory.mem_cells[6];
  wire [7:0] mem_07 = dut.u_memory.mem_cells[7];
  wire [7:0] mem_08 = dut.u_memory.mem_cells[8];
  wire [7:0] mem_09 = dut.u_memory.mem_cells[9];
  wire [7:0] mem_10 = dut.u_memory.mem_cells[10];
  wire [7:0] mem_11 = dut.u_memory.mem_cells[11];
  wire [7:0] mem_12 = dut.u_memory.mem_cells[12];
  wire [7:0] mem_13 = dut.u_memory.mem_cells[13];
  wire [7:0] mem_14 = dut.u_memory.mem_cells[14];
  wire [7:0] mem_15 = dut.u_memory.mem_cells[15];
  wire [7:0] mem_16 = dut.u_memory.mem_cells[16];
  wire [7:0] mem_17 = dut.u_memory.mem_cells[17];
  wire [7:0] mem_18 = dut.u_memory.mem_cells[18];
  wire [7:0] mem_19 = dut.u_memory.mem_cells[19];
  wire [7:0] mem_20 = dut.u_memory.mem_cells[20];
  wire [7:0] mem_21 = dut.u_memory.mem_cells[21];
  wire [7:0] mem_22 = dut.u_memory.mem_cells[22];
  wire [7:0] mem_23 = dut.u_memory.mem_cells[23];
  wire [7:0] mem_24 = dut.u_memory.mem_cells[24];
  wire [7:0] mem_25 = dut.u_memory.mem_cells[25];
  wire [7:0] mem_26 = dut.u_memory.mem_cells[26];
  wire [7:0] mem_27 = dut.u_memory.mem_cells[27];
  wire [7:0] mem_28 = dut.u_memory.mem_cells[28];
  wire [7:0] mem_29 = dut.u_memory.mem_cells[29];
  wire [7:0] mem_30 = dut.u_memory.mem_cells[30];
  wire [7:0] mem_31 = dut.u_memory.mem_cells[31];

  // ------------------------------------------------------------
  // Readable waveform labels
  // ------------------------------------------------------------
  reg [8*12:1] wave_state_name;
  reg [8*5 :1] wave_opcode_name;
  reg [8*40:1] wave_program_line;
  reg [8*32:1] wave_expected_action;

  always @(*) begin
    case (wave_state)
      INST_ADDR:  wave_state_name = "INST_ADDR   ";
      INST_FETCH: wave_state_name = "INST_FETCH  ";
      INST_LOAD:  wave_state_name = "INST_LOAD   ";
      IDLE:       wave_state_name = "IDLE        ";
      OP_ADDR:    wave_state_name = "OP_ADDR     ";
      OP_FETCH:   wave_state_name = "OP_FETCH    ";
      ALU_OP:     wave_state_name = "ALU_OP      ";
      STORE:      wave_state_name = "STORE       ";
      default:    wave_state_name = "UNKNOWN     ";
    endcase
  end

  always @(*) begin
    case (wave_opcode)
      HLT:     wave_opcode_name = "HLT  ";
      SKZ:     wave_opcode_name = "SKZ  ";
      ADD:     wave_opcode_name = "ADD  ";
      AND:     wave_opcode_name = "AND  ";
      XOR:     wave_opcode_name = "XOR  ";
      LDA:     wave_opcode_name = "LDA  ";
      STO:     wave_opcode_name = "STO  ";
      JMP:     wave_opcode_name = "JMP  ";
      default: wave_opcode_name = "UNK  ";
    endcase
  end

  always @(*) begin
    case (wave_pc)
      5'd0:
        wave_program_line =
          "00 LDA 24  AC<-MEM[24]=5             ";

      5'd1:
        wave_program_line =
          "01 ADD 25  AC<-AC+MEM[25]=8          ";

      5'd2:
        wave_program_line =
          "02 STO 26  MEM[26]<-AC=8             ";

      5'd3:
        wave_program_line =
          "03 XOR 24  AC<-8^5=13                ";

      5'd4:
        wave_program_line =
          "04 AND 25  AC<-13&3=1                ";

      5'd5:
        wave_program_line =
          "05 STO 27  MEM[27]<-1                ";

      5'd6:
        wave_program_line =
          "06 LDA 28  AC<-0                     ";

      5'd7:
        wave_program_line =
          "07 SKZ     zero, skip next           ";

      5'd8:
        wave_program_line =
          "08 STO 29  MUST BE SKIPPED           ";

      5'd9:
        wave_program_line =
          "09 LDA 25  AC<-3                     ";

      5'd10:
        wave_program_line =
          "10 SKZ     non-zero, no skip         ";

      5'd11:
        wave_program_line =
          "11 STO 30  MEM[30]<-3                ";

      5'd12:
        wave_program_line =
          "12 JMP 14  jump to 14                ";

      5'd13:
        wave_program_line =
          "13 STO 31  MUST BE SKIPPED           ";

      5'd14:
        wave_program_line =
          "14 LDA 26  AC<-MEM[26]=8             ";

      5'd15:
        wave_program_line =
          "15 ADD 27  AC<-8+1=9                 ";

      5'd16:
        wave_program_line =
          "16 STO 23  MEM[23]<-9                ";

      5'd17:
        wave_program_line =
          "17 HLT     halt CPU                  ";

      default:
        wave_program_line =
          "outside programmed instruction area ";
    endcase
  end

  always @(*) begin
    if (wave_skip_taken) begin
      wave_expected_action =
        "SKZ TAKEN: PC increments again ";
    end
    else if (
      (wave_opcode == SKZ) &&
      (wave_state == ALU_OP) &&
      !wave_zero
    ) begin
      wave_expected_action =
        "SKZ NOT TAKEN                  ";
    end
    else if (wave_jump_taken) begin
      wave_expected_action =
        "JMP TAKEN: PC loads operand    ";
    end
    else if (wave_store_taken) begin
      wave_expected_action =
        "STO WRITE TO MEMORY            ";
    end
    else if (wave_ac_load_event) begin
      wave_expected_action =
        "AC LOAD FROM ALU               ";
    end
    else if (wave_mem_read_event) begin
      wave_expected_action =
        "MEMORY READ                    ";
    end
    else if (wave_mem_write_event) begin
      wave_expected_action =
        "MEMORY WRITE                   ";
    end
    else if (halt) begin
      wave_expected_action =
        "HALT ASSERTED                  ";
    end
    else begin
      wave_expected_action =
        "normal CPU cycle               ";
    end
  end

  // ------------------------------------------------------------
  // Waveform dump
  // ------------------------------------------------------------
  initial begin
    $timeformat(-9, 0, " ns", 10);

    $dumpfile("CPU_tb_wave.vcd");
    $dumpvars(0, CPU_tb);

`ifdef USE_SHM
    $shm_open("CPU_tb_wave.shm");
    $shm_probe(CPU_tb, "ASCM");
`endif
  end

  // ------------------------------------------------------------
  // Helper tasks
  // ------------------------------------------------------------
  task check_mem;
    input [4:0] addr;
    input [7:0] expected;

    begin
      tests = tests + 1;

      if (dut.u_memory.mem_cells[addr] !== expected) begin
        errors = errors + 1;

        $display(
          "FAIL: MEM[%0d] = 0x%02h, expected 0x%02h",
          addr,
          dut.u_memory.mem_cells[addr],
          expected
        );
      end
      else begin
        $display(
          "PASS: MEM[%0d] = 0x%02h",
          addr,
          expected
        );
      end
    end
  endtask

  task check_ac;
    input [7:0] expected;

    begin
      tests = tests + 1;

      if (wave_ac !== expected) begin
        errors = errors + 1;

        $display(
          "FAIL: AC = 0x%02h, expected 0x%02h",
          wave_ac,
          expected
        );
      end
      else begin
        $display(
          "PASS: AC = 0x%02h",
          expected
        );
      end
    end
  endtask

  task check_halt;
    begin
      tests = tests + 1;

      if (halt !== 1'b1) begin
        errors = errors + 1;

        $display(
          "FAIL: halt = %b, expected 1",
          halt
        );
      end
      else begin
        $display("PASS: halt asserted");
      end
    end
  endtask

  task check_pc;
    input [4:0] expected;

    begin
      tests = tests + 1;

      if (wave_pc !== expected) begin
        errors = errors + 1;

        $display(
          "FAIL: PC = %0d, expected %0d",
          wave_pc,
          expected
        );
      end
      else begin
        $display(
          "PASS: PC = %0d",
          expected
        );
      end
    end
  endtask

  // ------------------------------------------------------------
  // Program and data initialization
  // ------------------------------------------------------------
  initial begin
    rst         = 1'b1;
    errors      = 0;
    tests       = 0;
    cycle_count = 0;

    for (i = 0; i < 32; i = i + 1) begin
      dut.u_memory.mem_cells[i] = 8'h00;
    end

    // Instruction encoding:
    // {opcode[2:0], operand[4:0]}
    dut.u_memory.mem_cells[0]  = 8'hB8; // LDA 24
    dut.u_memory.mem_cells[1]  = 8'h59; // ADD 25
    dut.u_memory.mem_cells[2]  = 8'hDA; // STO 26
    dut.u_memory.mem_cells[3]  = 8'h98; // XOR 24
    dut.u_memory.mem_cells[4]  = 8'h79; // AND 25
    dut.u_memory.mem_cells[5]  = 8'hDB; // STO 27
    dut.u_memory.mem_cells[6]  = 8'hBC; // LDA 28
    dut.u_memory.mem_cells[7]  = 8'h20; // SKZ
    dut.u_memory.mem_cells[8]  = 8'hDD; // STO 29, skipped
    dut.u_memory.mem_cells[9]  = 8'hB9; // LDA 25
    dut.u_memory.mem_cells[10] = 8'h20; // SKZ, not skipped
    dut.u_memory.mem_cells[11] = 8'hDE; // STO 30
    dut.u_memory.mem_cells[12] = 8'hEE; // JMP 14
    dut.u_memory.mem_cells[13] = 8'hDF; // STO 31, skipped
    dut.u_memory.mem_cells[14] = 8'hBA; // LDA 26
    dut.u_memory.mem_cells[15] = 8'h5B; // ADD 27
    dut.u_memory.mem_cells[16] = 8'hD7; // STO 23
    dut.u_memory.mem_cells[17] = 8'h00; // HLT

    // Data memory and sentinels.
    dut.u_memory.mem_cells[23] = 8'h00;
    dut.u_memory.mem_cells[24] = 8'd5;
    dut.u_memory.mem_cells[25] = 8'd3;
    dut.u_memory.mem_cells[26] = 8'h00;
    dut.u_memory.mem_cells[27] = 8'h00;
    dut.u_memory.mem_cells[28] = 8'd0;
    dut.u_memory.mem_cells[29] = 8'hAA;
    dut.u_memory.mem_cells[30] = 8'h00;
    dut.u_memory.mem_cells[31] = 8'hBB;

    if (VERBOSE) begin
      $display(
        "============================================================"
      );
      $display("CPU WAVEFORM TEST START");
      $display(
        "Open CPU_tb_wave.vcd or CPU_tb_wave.shm to view many signals."
      );
      $display(
        "============================================================"
      );
    end

    // Keep reset high for four clock edges.
    repeat (4) @(posedge clk);
    #1 rst = 1'b0;
  end

  // ------------------------------------------------------------
  // Optional console trace
  // ------------------------------------------------------------
  always @(posedge clk) begin
    if (rst) begin
      cycle_count <= 0;

      if (VERBOSE) begin
        $display(
          "t=%0t | RESET | PC=%02d state=%0d AC=0x%02h",
          $time,
          wave_pc,
          wave_state,
          wave_ac
        );
      end
    end
    else begin
      cycle_count <= cycle_count + 1;

      if (VERBOSE) begin
        $display(
          "t=%0t | cyc=%03d | PC=%02d | state=%0d | op=%b | operand=%02d | addr=%02d | bus=0x%02h | AC=0x%02h | ALU=0x%02h | zero=%b | rd=%b wr=%b ld_ir=%b ld_ac=%b inc_pc=%b ld_pc=%b halt=%b",
          $time,
          cycle_count,
          wave_pc,
          wave_state,
          wave_opcode,
          wave_operand,
          wave_mem_addr,
          wave_data_bus,
          wave_ac,
          wave_alu_out,
          wave_zero,
          wave_rd,
          wave_wr,
          wave_ld_ir,
          wave_ld_ac,
          wave_inc_pc,
          wave_ld_pc,
          halt
        );
      end
    end
  end

  // ------------------------------------------------------------
  // End condition and final checks
  // ------------------------------------------------------------
  initial begin
    wait (halt === 1'b1);

    // Keep a few cycles after halt visible in waveform.
    repeat (10) @(posedge clk);

    $display(
      "============================================================"
    );
    $display("CPU FINAL CHECKS");
    $display(
      "============================================================"
    );

    check_halt();

    check_mem(26, 8'd8);
    check_mem(27, 8'd1);
    check_mem(29, 8'hAA);
    check_mem(30, 8'd3);
    check_mem(31, 8'hBB);
    check_mem(23, 8'd9);

    check_ac(8'd9);
    check_pc(5'd18);

    $display(
      "============================================================"
    );

    if (errors == 0) begin
      $display(
        "CPU WAVEFORM TEST STATUS: PASS (%0d checks)",
        tests
      );
    end
    else begin
      $display(
        "CPU WAVEFORM TEST STATUS: FAIL (%0d errors / %0d checks)",
        errors,
        tests
      );
    end

    $display(
      "============================================================"
    );

    $finish;
  end

  // ------------------------------------------------------------
  // Timeout protection
  // ------------------------------------------------------------
  initial begin
    #50000;

    $display("FAIL: timeout. CPU did not halt.");
    $finish;
  end

endmodule