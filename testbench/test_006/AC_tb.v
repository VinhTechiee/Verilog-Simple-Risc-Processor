`timescale 1ns / 1ps

// ============================================================
// AC_tb.v — Testbench for Accumulator (AC)
// Covers 8 scenarios:
//   TC1: System Reset
//   TC2: Load Data
//   TC3: Data Stability
//   TC4: Feedback to ALU
//   TC5: Interaction with Data Bus
//   TC6: Reset Priority
//   TC7: Boundary Values
//   TC8: Rapid Toggling
// ============================================================
module AC_tb;

  // ── Signals ─────────────────────────────────────────
  reg        clk;
  reg        rst;
  reg        ld_ac;
  reg  [7:0] data_in;
  wire [7:0] ac_out;

  // ── DUT instantiation ────────────────────────────────
  accumulator uut (
      .clk    (clk),
      .rst    (rst),
      .ld_ac  (ld_ac),
      .data_in(data_in),
      .ac_out (ac_out)
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
      $display("%s | rst=%b | ld_ac=%b | data_in=%0d | ac_out=%0d", tc_name, rst, ld_ac, data_in,
               ac_out);
    end
  endtask

  initial begin
    // Init
    rst = 1;
    ld_ac = 0;
    data_in = 8'd0;
    #1;

    // ── TC1: System Reset ────────────────────────────
    $display("--- TC1: System Reset ---");
    display_state("TC1  ");  // Expect: ac_out = 0 
    rst = 0;

    // ── TC2: Load Data (ALU Result) ──────────────────
    $display("--- TC2: Load Data (ALU Result) ---");
    ld_ac   = 1;
    data_in = 8'd150;  // Assume result from ALU is 150
    display_state("TC2.1");  // Expect: ac_out = 150

    data_in = 8'd200;
    display_state("TC2.2");  // Expect: ac_out = 200

    // ── TC3: Data Stability (Idle/Fetch) ─────────────
    $display("--- TC3: Data Stability (Idle/Fetch) ---");
    ld_ac   = 0;
    data_in = 8'd255;  // Change input data
    display_state("TC3.1");  // Expect: ac_out holds 200
    display_state("TC3.2");  // Expect: ac_out holds 200

    // ── TC4: Feedback to ALU ─────────────────────────
    $display("--- TC4: Feedback to ALU ---");
    // This case verifies that ac_out (inA of ALU) is always ready
    display_state("TC4  ");  // Expect: ac_out = 200

    // ── TC5: Interaction with Data Bus ───────────────
    $display("--- TC5: Interaction with Data Bus ---");
    // Simulate loading a new value in preparation to write to Memory
    ld_ac   = 1;
    data_in = 8'd100;
    display_state("TC5.1");  // Expect: ac_out = 100
    ld_ac = 0;
    display_state("TC5.2");  // Value holds stable during write cycle

    // ── TC6: Reset Priority ──────────────────────────
    $display("--- TC6: Reset Priority Check ---");
    ld_ac   = 1;
    data_in = 8'd123;
    rst     = 1;  // Assert Reset while load is active
    display_state("TC6.1");  // Expect: ac_out = 0 (Reset wins)
    rst = 0;
    display_state("TC6.2");  // Expect: ac_out = 123 (Normal load resumes)

    // ── TC7: Boundary Values ─────────────────────────
    $display("--- TC7: Boundary Values ---");
    ld_ac   = 1;
    data_in = 8'hFF;  // All 1s
    display_state("TC7.1");
    data_in = 8'h00;  // All 0s
    display_state("TC7.2");

    // ── TC8: Rapid Toggling ──────────────────────────
    $display("--- TC8: Rapid Toggling ---");
    ld_ac   = 1;
    data_in = 8'hAA;
    display_state("TC8.1");
    data_in = 8'h55;
    display_state("TC8.2");
    ld_ac   = 0;
    data_in = 8'h12;
    display_state("TC8.3");  // Expect: Holds 8'h55

    $display("--- DONE ---");
    $finish;
  end
endmodule
