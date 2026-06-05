`timescale 1ns / 1ps

// ============================================================
// PC_tb.v — Testbench for Program Counter (PC)
// PC is 5-bit according to the assignment: 32 memory addresses.
// Covers:
//   TC1: Synchronous reset
//   TC2: Increment
//   TC3: Load
//   TC4: Priority rst > ld_pc > inc_pc
//   TC5: Hold
//   TC6: 5-bit wrap-around
//   TC7: Jump & increment
//   TC8: Reset from non-zero value
//   TC9: Data noise immunity
// ============================================================
module PC_tb;

  reg       clk;
  reg       rst;
  reg       ld_pc;
  reg       inc_pc;
  reg [4:0] data_in;
  wire [4:0] pc_out;

  PC uut (
      .clk    (clk),
      .rst    (rst),
      .ld_pc  (ld_pc),
      .inc_pc (inc_pc),
      .data_in(data_in),
      .pc_out (pc_out)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task tick;
    input [63:0] cycle;
    begin
      @(posedge clk);
      #1;
      $display("cycle=%0d | rst=%b | ld_pc=%b | inc_pc=%b | data_in=%0d | pc_out=%0d",
               cycle, rst, ld_pc, inc_pc, data_in, pc_out);
    end
  endtask

  initial begin
    rst = 1;
    ld_pc = 0;
    inc_pc = 0;
    data_in = 5'd0;

    $display("--- TC1: Reset ---");
    tick(1);  // pc_out = 0
    rst = 0;

    $display("--- TC2: Increment ---");
    inc_pc = 1;
    tick(2);  // pc_out = 1
    tick(3);  // pc_out = 2
    tick(4);  // pc_out = 3
    inc_pc = 0;

    $display("--- TC3: Load ---");
    data_in = 5'd20;
    ld_pc   = 1;
    tick(5);  // pc_out = 20
    ld_pc = 0;
    tick(6);  // hold 20

    $display("--- TC4: Priority rst > ld_pc > inc_pc ---");
    data_in = 5'd25;
    rst = 1;
    ld_pc = 1;
    inc_pc = 1;
    tick(7);  // reset dominates -> 0
    rst = 0;
    tick(8);  // ld_pc dominates -> 25
    ld_pc = 0;
    tick(9);  // inc_pc -> 26
    inc_pc = 0;

    $display("--- TC5: Hold State ---");
    tick(10); // hold 26
    tick(11); // hold 26

    $display("--- TC6: 5-bit Wrap-around ---");
    data_in = 5'd31;
    ld_pc   = 1;
    tick(12); // pc_out = 31
    ld_pc  = 0;
    inc_pc = 1;
    tick(13); // pc_out wraps to 0
    inc_pc = 0;

    $display("--- TC7: Jump & Increment ---");
    data_in = 5'd10;
    ld_pc   = 1;
    tick(14); // pc_out = 10
    ld_pc  = 0;
    inc_pc = 1;
    tick(15); // 11
    tick(16); // 12
    inc_pc = 0;

    $display("--- TC8: Reset from Non-Zero Value ---");
    data_in = 5'd30;
    ld_pc   = 1;
    tick(17); // pc_out = 30
    ld_pc = 0;
    rst   = 1;
    tick(18); // pc_out = 0
    rst = 0;

    $display("--- TC9: Data Noise Immunity ---");
    inc_pc = 1;
    tick(19); // pc_out = 1
    data_in = 5'd31;
    tick(20); // pc_out = 2, not affected by data_in
    inc_pc = 0;

    $display("--- DONE ---");
    $finish;
  end

endmodule
