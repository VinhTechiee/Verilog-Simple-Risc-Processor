`timescale 1ns / 1ps

// ============================================================
// PC_tb.v — Testbench for Program Counter (PC)
// Covers 4 scenarios described in the project spec:
//   TC1: Synchronous reset
//   TC2: Increment (inc_pc)
//   TC3: Load (ld_pc)
//   TC4: Priority: rst > ld_pc > inc_pc
// ============================================================
module PC_tb;

    // ── Signals ─────────────────────────────────────────
    reg         clk;
    reg         rst;
    reg         ld_pc;
    reg         inc_pc;
    reg  [31:0] data_in;
    wire [31:0] pc_out;

    // ── DUT instantiation ────────────────────────────────
    PC uut (
        .clk     (clk),
        .rst     (rst),
        .ld_pc   (ld_pc),
        .inc_pc  (inc_pc),
        .data_in (data_in),
        .pc_out  (pc_out)
    );

    // ── Clock: 10 ns period ──────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ── Task: tick one clock and display state ───────────
    task tick;
        input [63:0] cycle;
        begin
            @(posedge clk); #1;
            $display("cycle=%0d | rst=%b | ld_pc=%b | inc_pc=%b | data_in=%0d | pc_out=%0d",
                      cycle, rst, ld_pc, inc_pc, data_in, pc_out);
        end
    endtask

    integer i;

    initial begin
        // Init
        rst = 1; ld_pc = 0; inc_pc = 0; data_in = 0;

        // ── TC1: Reset ───────────────────────────────────
        $display("--- TC1: Reset ---");
        tick(1);   // rst=1 -> pc_out should be 0
        rst = 0;

        // ── TC2: Increment ───────────────────────────────
        $display("--- TC2: Increment ---");
        inc_pc = 1;
        tick(2);   // pc_out = 1
        tick(3);   // pc_out = 2
        tick(4);   // pc_out = 3
        inc_pc = 0;

        // ── TC3: Load ────────────────────────────────────
        $display("--- TC3: Load ---");
        data_in = 32'd20;
        ld_pc   = 1;
        tick(5);   // pc_out = 20
        ld_pc   = 0;
        tick(6);   // pc_out = 20 (hold, no inc)

        // ── TC4: Priority rst > ld_pc > inc_pc ───────────
        $display("--- TC4: Priority ---");
        data_in = 32'd99;
        rst = 1; ld_pc = 1; inc_pc = 1;
        tick(7);   // rst dominates -> pc_out = 0
        rst = 0;
        tick(8);   // ld_pc dominates over inc_pc -> pc_out = 99
        ld_pc = 0;
        tick(9);   // inc_pc -> pc_out = 100
        inc_pc = 0;

        // -- TC5: Hold/Idle State -- [cite: 36]
        $display("--- TC5: Hold State ---");
        rst = 0; ld_pc = 0; inc_pc = 0;
        tick(10);  // pc_out stays 100
        tick(11);  // pc_out stays 100

        // -- TC6: Wrap-around (32-bit limit) -- [cite: 34]
        $display("--- TC6: Wrap-around ---");
        data_in = 32'hFFFFFFFF; // Max 32-bit value
        ld_pc = 1;
        tick(12);  // pc_out = 4294967295
        ld_pc = 0; inc_pc = 1;
        tick(13);  // pc_out wraps to 0
        inc_pc = 0;

        // -- TC7: Jump & Increment Sequence --
        $display("--- TC7: Jump & Increment ---");
        data_in = 32'd1000;
        ld_pc = 1;
        tick(14);  // pc_out = 1000
        ld_pc = 0; inc_pc = 1;
        tick(15);  // pc_out = 1001
        tick(16);  // pc_out = 1002
        inc_pc = 0;

        // -- TC8: Reset from Non-Zero Value --
        $display("--- TC8: Reset from High Value ---");
        data_in = 32'hABCDE000;
        ld_pc = 1;
        tick(17);  // pc_out = 2882396160
        ld_pc = 0;
        rst = 1;   // Reset
        tick(18);  // pc_out must be 0
        rst = 0;

        // -- TC9: Data Noise Immunity --
        $display("--- TC9: Data Noise Immunity ---");
        inc_pc = 1;
        tick(19);  // pc_out = 1
        data_in = 32'hFFFFFFFF; 
        tick(20);  // pc_out = 2 
        inc_pc = 0;

        $display("--- DONE ---");
        $finish;
    end

endmodule