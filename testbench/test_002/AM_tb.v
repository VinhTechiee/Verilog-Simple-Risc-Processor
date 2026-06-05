`timescale 1ns / 1ps

// ============================================================
// AM_tb.v — Testbench for Address Mux
// Default WIDTH is 5 because CPU memory has 32 addresses.
// Covers:
//   TC1: Select pc_addr
//   TC2: Select ir_addr
//   TC3: Toggle sel
//   TC4: Parameter override
//   TC5: Stability
//   TC6: Edge case addresses
//   TC7: Async response
// ============================================================
module AM_tb;

  reg  [4:0] pc_addr;
  reg  [4:0] ir_addr;
  reg        sel;
  wire [4:0] addr_out;

  address_mux uut (
      .pc_addr (pc_addr),
      .ir_addr (ir_addr),
      .sel     (sel),
      .addr_out(addr_out)
  );

  reg  [15:0] pc_addr_16;
  reg  [15:0] ir_addr_16;
  wire [15:0] addr_out_16;

  address_mux #(
      .WIDTH(16)
  ) uut_16 (
      .pc_addr (pc_addr_16),
      .ir_addr (ir_addr_16),
      .sel     (sel),
      .addr_out(addr_out_16)
  );

  task display_state;
    input [8*5:1] tc_name;
    begin
      #1;
      $display("%s | sel=%b | pc_addr=%0d | ir_addr=%0d | addr_out=%0d",
               tc_name, sel, pc_addr, ir_addr, addr_out);
    end
  endtask

  initial begin
    pc_addr = 5'd10;
    ir_addr = 5'd20;
    sel = 0;

    pc_addr_16 = 16'd500;
    ir_addr_16 = 16'd600;

    $display("--- TC1: Select pc_addr ---");
    sel = 1;
    display_state("TC1  ");

    $display("--- TC2: Select ir_addr ---");
    sel = 0;
    display_state("TC2  ");

    $display("--- TC3: Toggle sel ---");
    pc_addr = 5'd5;
    ir_addr = 5'd25;
    sel = 1;
    display_state("TC3.1");
    sel = 0;
    display_state("TC3.2");
    sel = 1;
    display_state("TC3.3");

    $display("--- TC4: Parameter Override (WIDTH=16) ---");
    sel = 1;
    #1;
    $display("TC4.1 | sel=%b | pc_addr_16=%0d | ir_addr_16=%0d | addr_out_16=%0d",
             sel, pc_addr_16, ir_addr_16, addr_out_16);
    sel = 0;
    #1;
    $display("TC4.2 | sel=%b | pc_addr_16=%0d | ir_addr_16=%0d | addr_out_16=%0d",
             sel, pc_addr_16, ir_addr_16, addr_out_16);

    $display("--- TC5: Stability Check ---");
    sel = 1;
    pc_addr = 5'd7;
    ir_addr = 5'd12;
    display_state("TC5.1");
    sel = 0;
    pc_addr = 5'd15;
    ir_addr = 5'd31;
    display_state("TC5.2");

    $display("--- TC6: Edge Case Addresses ---");
    sel = 1;
    pc_addr = 5'd0;
    ir_addr = 5'd31;
    display_state("TC6.1");
    sel = 0;
    display_state("TC6.2");

    $display("--- TC7: Async Response ---");
    sel = 1;
    #1;
    pc_addr = 5'd11;
    display_state("TC7.1");
    pc_addr = 5'd22;
    display_state("TC7.2");
    pc_addr = 5'd31;
    display_state("TC7.3");

    $display("--- DONE ---");
    $finish;
  end

endmodule
