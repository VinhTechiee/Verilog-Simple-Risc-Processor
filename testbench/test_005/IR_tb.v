`timescale 1ns / 1ps

module IR_tb;
    // ── Khai báo tín hiệu ────────────────────────────
    reg clk;
    reg rst;
    reg ld_ir;
    reg [31:0] data_in;

    wire [2:0] opcode;
    wire [4:0] operand;

    // ── Khởi tạo module ──────────────────────────────
    instruction_register uut (
        .clk(clk),
        .rst(rst),
        .ld_ir(ld_ir),
        .data_in(data_in),
        .opcode(opcode),
        .operand(operand)
    );

    // ── Tạo xung Clock ───────────────────────────────
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ── Task hiển thị trạng thái ─────────────────────
    task display_state;
        input [8*5:1] tc_name;
        begin
            @(posedge clk);
            #1; // Đợi sau cạnh lên để dữ liệu cập nhật
            $display("%s | rst=%b | ld_ir=%b | data_in=0x%08X | opcode=%b | operand=%b",
                     tc_name, rst, ld_ir, data_in, opcode, operand);
        end
    endtask

    initial begin
        // Khởi tạo
        rst = 1;
        ld_ir = 0;
        data_in = 32'd0;
        #1;
        
        // ── TC1: Reset hệ thống ───────────────────────
        $display("--- TC1: System Reset ---");
        display_state("TC1.1"); // Kỳ vọng opcode=0, operand=0
        
        rst = 0; // Bỏ reset
        
        // ── TC2: Nạp lệnh (Load Instruction) ──────────
        $display("--- TC2: Load Instruction ---");
        ld_ir = 1;
        // Instruction 1: Opcode = 101 (LDA), Operand = 10101
        // Lệnh ghép: [7:5] = 101, [4:0] = 10101 -> 1011_0101 = 0xB5
        data_in = 32'h000000B5; 
        display_state("TC2.1"); // Kỳ vọng: opcode=101, operand=10101
        
        // Instruction 2: Opcode = 010 (ADD), Operand = 00011
        // Lệnh ghép: [7:5] = 010, [4:0] = 00011 -> 0100_0011 = 0x43
        data_in = 32'h00000043;
        display_state("TC2.2"); // Kỳ vọng: opcode=010, operand=00011

        // ── TC3: Giữ giá trị (Hold Value) ─────────────
        $display("--- TC3: Hold Value ---");
        ld_ir = 0; // Ngắt tín hiệu nạp lệnh
        data_in = 32'hFFFFFFFF; // Thay đổi data trên bus
        display_state("TC3.1"); // Kỳ vọng: opcode=010, operand=00011 (vẫn giữ nguyên)
        display_state("TC3.2"); // Kỳ vọng: opcode=010, operand=00011

        // ── TC4: Phân tách mã lệnh (Extract logic) ────
        $display("--- TC4: Extract Opcode and Operand ---");
        // Instruction 3: Opcode = 111 (JMP), Operand = 11111
        // Lệnh ghép: [7:5] = 111, [4:0] = 11111 -> 1111_1111 = 0xFF
        // Padding phần cao bằng 1 pattern bất kỳ (VD: 0xDEADBE)
        ld_ir = 1;
        data_in = 32'hDEADBEFF;
        display_state("TC4.1"); // Kỳ vọng: opcode=111, operand=11111
        
        // Instruction 4: Opcode = 000 (HLT), Operand = 00000
        data_in = 32'h12345600;
        display_state("TC4.2"); // Kỳ vọng: opcode=000, operand=00000

        $display("--- TC5: Reset Priority ---");
        ld_ir = 1;
        data_in = 32'hFFFFFFFF; // Cố gắng nạp dữ liệu toàn 1
        rst = 1;                 // Nhưng đồng thời kích hoạt reset
        display_state("TC5.1");  // Kỳ vọng: opcode=000, operand=00000
        rst = 0;
        display_state("TC5.2");  // Sau khi bỏ reset, dữ liệu FFFF được nạp (opcode=111, op=11111)

        // -- TC6: Chống nhiễu dữ liệu (Bus Noise Immunity) --
        // Thay đổi data_in liên tục khi ld_ir = 0
        $display("--- TC6: Bus Noise Immunity ---");
        ld_ir = 0;
        data_in = 32'hAAAAAAAA; #2;
        data_in = 32'h55555555; #2;
        data_in = 32'h12345678; 
        display_state("TC6.1");  // Kỳ vọng: vẫn giữ giá trị từ TC5.2 (111, 11111)

        // -- TC7: Kiểm tra Masking (High-bit Masking) --
        // Đảm bảo chỉ các bit [7:0] ảnh hưởng đến đầu ra, các bit còn lại bị bỏ qua
        $display("--- TC7: High-bit Masking ---");
        ld_ir = 1;
        // Nạp lệnh ADD (010) Operand (01010) với bit cao là 0xABCDEF
        data_in = 32'hABCDEF4A; // 4A = 010_01010
        display_state("TC7.1"); // Kỳ vọng: opcode=010, operand=01010
        
        // Nạp lệnh LDA (101) Operand (11111) với bit cao là 0x000000
        data_in = 32'h000000BF; // BF = 101_11111
        display_state("TC7.2"); // Kỳ vọng: opcode=101, operand=11111

        $display("--- DONE ---");
        $finish;
    end
endmodule
