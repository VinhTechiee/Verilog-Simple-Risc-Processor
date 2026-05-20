`timescale 1ns / 1ps

module ALU_tb;
    // ── Khai báo tín hiệu ────────────────────────────
    reg [31:0] inA;
    reg [31:0] inB;
    reg [2:0] opcode;
    wire [31:0] alu_out;
    wire zero;

    // ── Khởi tạo ALU ─────────────────────────────────
    alu uut (
        .inA(inA),
        .inB(inB),
        .opcode(opcode),
        .alu_out(alu_out),
        .zero(zero)
    );

    // ── Task hiển thị ────────────────────────────────
    task display_state;
        input [8*5:1] tc_name;
        begin
            #1; // Đợi combinational logic
            $display("%s | opcode=%b | inA=%0d | inB=%0d | zero=%b | alu_out=%0d", 
                      tc_name, opcode, inA, inB, zero, alu_out);
        end
    endtask

    initial begin
        // Khởi tạo
        inA = 0;
        inB = 0;
        opcode = 3'b000;
        #10;

        // ── TC1: Kiểm tra tín hiệu trạng thái Zero ────
        $display("--- TC1: Zero Status Flag ---");
        inA = 32'd0;
        display_state("TC1.1"); // zero = 1
        inA = 32'd50;
        display_state("TC1.2"); // zero = 0

        // ── TC2: Phép tính số học & Logic ─────────────
        $display("--- TC2: Arithmetic & Logic ---");
        inA = 32'd100;
        inB = 32'd25;
        
        // ADD
        opcode = 3'b010;
        display_state("ADD  "); // 125
        
        // AND (bitwise AND 100 & 25)
        opcode = 3'b011;
        display_state("AND  "); // 0
        
        // XOR (bitwise XOR 100 ^ 25)
        opcode = 3'b100;
        display_state("XOR  "); // 125

        // LDA (Output inB)
        opcode = 3'b101;
        display_state("LDA  "); // 25

        // ── TC3: Lệnh chuyển tiếp ─────────────────────
        $display("--- TC3: Transfer Operations ---");
        inA = 32'd999;
        inB = 32'd555;
        
        // HLT (Output inA)
        opcode = 3'b000;
        display_state("HLT  "); // 999
        
        // SKZ (Output inA)
        opcode = 3'b001;
        display_state("SKZ  "); // 999
        
        // STO (Output inA)
        opcode = 3'b110;
        display_state("STO  "); // 999
        
        // JMP (Output inA)
        opcode = 3'b111;
        display_state("JMP  "); // 999

        // ── TC4: Kiểm tra tính tổ hợp ─────────────────
        $display("--- TC4: Combinational Property ---");
        inA = 32'd10;
        inB = 32'd20;
        opcode = 3'b010; // ADD
        // Thay đổi không có clock
        #1;
        $display("TC4   | opcode=%b | inA=%0d | inB=%0d | zero=%b | alu_out=%0d", 
                 opcode, inA, inB, zero, alu_out); // Kỳ vọng 30

        
        $display("--- TC5: Boundary Cases ---");
        opcode = 3'b010; // ADD
        inA = 32'hFFFF_FFFF; 
        inB = 32'h0000_0001;
        display_state("TC5.1"); // Kỳ vọng: alu_out = 0 (Tràn số 32-bit)

        inA = 32'h7FFF_FFFF;
        inB = 32'h7FFF_FFFF;
        display_state("TC5.2"); // Cộng hai số dương lớn nhất

        // ── TC6: Complex Bitwise Logic ─────────────────────
        $display("--- TC6: Complex Logic ---");
        inA = 32'hAAAA_AAAA; // 101010...
        inB = 32'h5555_5555; // 010101...
        
        opcode = 3'b011; // AND
        display_state("AND_C"); // Kỳ vọng: 0
        
        opcode = 3'b100; // XOR
        display_state("XOR_C"); // Kỳ vọng: FFFFFFFF (Nếu thực hiện XOR thực thụ)

        // ── TC7: Zero Flag Independence ────────────────────
        $display("--- TC7: Zero Flag Independence ---");
        // Kiểm tra xem zero flag có thay đổi ngay lập tức khi inA đổi, 
        // bất kể opcode đang là gì.
        opcode = 3'b101; // LDA (Output là inB)
        inA = 32'd0; inB = 32'd100;
        #1;
        $display("TC7.1 | zero=%b | alu_out=%0d", zero, alu_out); // zero=1, out=100
        
        inA = 32'd1; inB = 32'd100;
        #1;
        $display("TC7.2 | zero=%b | alu_out=%0d", zero, alu_out); // zero=0, out=100
        
        $display("--- DONE ---");
        $finish;
    end
endmodule
