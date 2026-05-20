`timescale 1ns / 1ps

module CPU_tb;

    // -- DUT signals --
    reg  clk;
    reg  rst;
    wire halt;

    // -- Khởi tạo CPU (Top-level) --
    CPU uut (
        .clk (clk),
        .rst (rst),
        .halt(halt)
    );

    // -- Clock: 10 ns period --
    initial clk = 0;
    always #5 clk = ~clk;

    // -- Task hiển thị trạng thái hệ thống --
    task display_cpu_state;
        begin
            $display("time=%t | PC=%2d | State=%3b | Op=%3b | AC=%0d | Halt=%b",
                      $time, uut.pc_unit.pc_out, uut.control_unit.state, 
                      uut.opcode, uut.ac_unit.ac_out, halt);
        end
    endtask

    // -- Nạp chương trình và điều khiển mô phỏng --
    initial begin
        // 1. Nạp đoạn chương trình cụ thể từ README
        // LDA 20, ADD 21, STO 22, HLT
        uut.mem_unit.mem[0] = 32'hB4; // LDA 20 (Opcode 101, Operand 10100)
        uut.mem_unit.mem[1] = 32'h55; // ADD 21 (Opcode 010, Operand 10101)
        uut.mem_unit.mem[2] = 32'hD6; // STO 22 (Opcode 110, Operand 10110)
        uut.mem_unit.mem[3] = 32'h00; // HLT    (Opcode 000, Operand 00000)

        // 2. Nạp dữ liệu đầu vào theo README
        uut.mem_unit.mem[20] = 32'd5;
        uut.mem_unit.mem[21] = 32'd3;
        uut.mem_unit.mem[22] = 32'd0; // Nơi lưu kết quả

        // 3. Reset hệ thống
        rst = 1;
        repeat (2) @(posedge clk);
        #1; rst = 0;

        $display("--- CPU INTEGRATION TEST STARTED ---");
    end

    // Monitor trạng thái tại mỗi cạnh lên xung clock
    always @(posedge clk) begin
        if (!rst) display_cpu_state();
    end

    // Kiểm tra kết quả cuối cùng sau khi HLT
    initial begin
        wait (halt === 1'b1);
        repeat (2) @(posedge clk);

        $display("--- FINAL RESULT CHECK ---");
        $display("Mem[22] (Expected 8): %0d", uut.mem_unit.mem[22]);
        
        if (uut.mem_unit.mem[22] == 8)
            $display("--- TEST STATUS: PASS ---");
        else
            $display("--- TEST STATUS: FAIL ---");
            
        $finish;
    end

    // Safety Timeout
    initial #10000 $finish;

endmodule
