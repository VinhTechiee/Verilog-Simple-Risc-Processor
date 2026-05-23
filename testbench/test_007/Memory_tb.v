`timescale 1ns / 1ps

// ============================================================
// Memory_tb.v — Testbench for Memory
// Covers 5 scenarios described in the project spec:
//   TC1: Write Data
//   TC2: Read Data
//   TC3: High Impedance Check
//   TC4: Conflict Prevention
//   TC5: Data Persistence
// ============================================================
module Memory_tb;

  // ── Signals ─────────────────────────────────────────
  reg         clk;
  reg         rd;
  reg         wr;
  reg  [ 4:0] addr;  // 5-bit address for 32 memory cells
  wire [31:0] data;  // Bidirectional bus

  // Bus control signals from Testbench
  reg  [31:0] data_reg;

  // Inout control logic: Write only when wr=1 and rd=0
  assign data = (wr && !rd) ? data_reg : 32'hZZZZ_ZZZZ;

  // ── DUT instantiation ────────────────────────────────
  memory uut (
      .clk (clk),
      .rd  (rd),
      .wr  (wr),
      .addr(addr),
      .data(data)
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
      #1;  // Wait after posedge for data to stabilize
      $display("%s | rd=%b | wr=%b | addr=%0d | data=0x%08X", tc_name, rd, wr, addr, data);
    end
  endtask

  initial begin
    // Init
    rd       = 0;
    wr       = 0;
    addr     = 0;
    data_reg = 0;
    #10;

    // ── TC1: Write Data ──────────────────────────────
    $display("--- TC1: Write Data ---");
    wr       = 1;
    rd       = 0;
    addr     = 5'd10;
    data_reg = 32'hA5A5_A5A5;
    display_state("TC1.1");  // Write to memory cell 10 

    addr     = 5'd20;
    data_reg = 32'h1234_5678;
    display_state("TC1.2");  // Write to memory cell 20 
    wr = 0;

    // ── TC2: Read Data ───────────────────────────────
    $display("--- TC2: Read Data ---");
    wr   = 0;
    rd   = 1;
    addr = 5'd10;
    display_state("TC2.1");  // Expect: A5A5_A5A5
    addr = 5'd20;
    display_state("TC2.2");  // Expect: 1234_5678

    // ── TC3: High Impedance Check ────────────────────
    $display("--- TC3: High Impedance Check ---");
    wr   = 0;
    rd   = 0;  // No read, no write
    addr = 5'd10;
    display_state("TC3  ");  // Expect: data = ZZZZZZZZ

    // ── TC4: Conflict Prevention ─────────────────────
    $display("--- TC4: Conflict Prevention ---");
    // Per spec: Simultaneous read and write not allowed
    wr       = 1;
    rd       = 1;
    addr     = 5'd10;
    data_reg = 32'hFFFF_FFFF;
    display_state("TC4  ");  // Expect: System must handle safely (usually high-Z or priority)

    // ── TC5: Data Persistence ────────────────────────
    $display("--- TC5: Data Persistence ---");
    wr   = 0;
    rd   = 1;
    addr = 5'd10;
    display_state("TC5  ");  // Confirm data in cell 10 is still A5A5_A5A5 after conflict

    $display("--- DONE ---");
    $finish;
  end
endmodule
