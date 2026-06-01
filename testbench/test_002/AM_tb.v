`timescale 1ns / 1ps

module AM_tb;
  // ── Tín hiệu nội bộ (32-bit default) ────────────
  reg [31:0] pc_addr;
  reg [31:0] ir_addr;
  reg sel;
  wire [31:0] addr_out;

  // ── Khởi tạo module cần test (WIDTH = 32) ───────
  address_mux uut (
      .pc_addr (pc_addr),
      .ir_addr (ir_addr),
      .sel     (sel),
      .addr_out(addr_out)
  );

  // ── Khởi tạo module test Parameter (WIDTH = 16) ─
  reg  [15:0] pc_addr_16;
  reg  [15:0] ir_addr_16;
  wire [15:0] addr_out_16;

  address_mux #(
      .WIDTH(16)
  ) uut_16 (
      .pc_addr(pc_addr_16),
      .ir_addr(ir_addr_16),
      .sel(sel),
      .addr_out(addr_out_16)
  );

  // ── Task hiển thị kết quả (32-bit) ──────────────
  task display_state;
    input [8*5:1] tc_name;
    begin
      #1;  // Đợi combinational logic cập nhật
      $display("%s | sel=%b | pc_addr=%0d | ir_addr=%0d | addr_out=%0d", tc_name, sel, pc_addr,
               ir_addr, addr_out);
    end
  endtask

  initial begin
    // Khởi tạo
    pc_addr = 32'd1000;
    ir_addr = 32'd2000;
    sel = 0;

    pc_addr_16 = 16'd500;
    ir_addr_16 = 16'd600;

    // ── TC1: Lựa chọn địa chỉ lệnh (sel = 1) ─────
    $display("--- TC1: Select pc_addr ---");
    sel = 1;
    display_state("TC1  ");

    // ── TC2: Lựa chọn địa chỉ toán hạng (sel = 0) 
    $display("--- TC2: Select ir_addr ---");
    sel = 0;
    display_state("TC2  ");

    // ── TC3: Thay đổi tín hiệu sel liên tiếp ─────
    $display("--- TC3: Toggle sel ---");
    pc_addr = 32'd5555;
    ir_addr = 32'd9999;
    sel = 1;
    display_state("TC3.1");
    sel = 0;
    display_state("TC3.2");
    sel = 1;
    display_state("TC3.3");

    // ── TC4: Thay đổi parameter (WIDTH = 16) ─────
    $display("--- TC4: Parameter Override (WIDTH=16) ---");
    sel = 1;
    #1;
    $display("TC4.1 | sel=%b | pc_addr_16=%0d | ir_addr_16=%0d | addr_out_16=%0d", sel, pc_addr_16,
             ir_addr_16, addr_out_16);
    sel = 0;
    #1;
    $display("TC4.2 | sel=%b | pc_addr_16=%0d | ir_addr_16=%0d | addr_out_16=%0d", sel, pc_addr_16,
             ir_addr_16, addr_out_16);

    $display("--- TC5: Stability Check ---");
    sel = 1;
    pc_addr = 32'd7777;
    ir_addr = 32'd1234;
    display_state("TC5.1");
    sel = 0;
    pc_addr = 32'd5678;
    ir_addr = 32'd8888;
    display_state("TC5.2");

    $display("--- TC6: Edge Case Addresses ---");
    sel = 1;
    pc_addr = 32'd0;
    ir_addr = 32'd4294967295;
    display_state("TC6.1");
    sel = 0;
    display_state("TC6.2");

    $display("--- TC7: Async Response ---");
    sel = 1;
    #1;
    pc_addr = 32'd1111;
    display_state("TC7.1");
    pc_addr = 32'd2222;
    display_state("TC7.2");
    pc_addr = 32'd3333;
    display_state("TC7.3");

    $display("--- DONE ---");
    $finish;
  end
endmodule

