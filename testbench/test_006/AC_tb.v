`timescale 1ns / 1ps

module AC_tb;
  // -- Tín hiệu kết nối --
  reg         clk;
  reg         rst;
  reg         ld_ac;
  reg  [31:0] data_in;
  wire [31:0] ac_out;

  // -- Khởi tạo module AC (DUT) --
  accumulator uut (
      .clk    (clk),
      .rst    (rst),
      .ld_ac  (ld_ac),
      .data_in(data_in),
      .ac_out (ac_out)
  );

  // -- Tạo xung Clock: chu kỳ 10ns --
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // -- Task hiển thị trạng thái --
  task display_state;
    input [8*5:1] tc_name;
    begin
      @(posedge clk);
      #1;  // Đợi sau cạnh lên để dữ liệu ổn định
      $display("%s | rst=%b | ld_ac=%b | data_in=%0d | ac_out=%0d", tc_name, rst, ld_ac, data_in,
               ac_out);
    end
  endtask

  initial begin
    // Khởi tạo ban đầu
    rst = 1;
    ld_ac = 0;
    data_in = 32'd0;
    #1;

    // -- TC1: Kiểm tra chức năng reset hệ thống --
    $display("--- TC1: System Reset ---");
    display_state("TC1  ");  // Kỳ vọng: ac_out = 0 
    rst = 0;

    // -- TC2: Kiểm tra chức năng nạp dữ liệu (ld_ac = 1) --
    $display("--- TC2: Load Data (ALU Result) ---");
    ld_ac   = 1;
    data_in = 32'd150;  // Giả sử kết quả từ ALU là 150
    display_state("TC2.1");  // Kỳ vọng: ac_out = 150 [cite: 97, 98]

    data_in = 32'd300;
    display_state("TC2.2");  // Kỳ vọng: ac_out = 300

    // -- TC3: Kiểm tra tính ổn định dữ liệu (ld_ac = 0) --
    $display("--- TC3: Data Stability (Idle/Fetch) ---");
    ld_ac   = 0;
    data_in = 32'd999;  // Thay đổi dữ liệu ngõ vào
    display_state("TC3.1");  // Kỳ vọng: ac_out vẫn giữ 300 [cite: 99, 100]
    display_state("TC3.2");  // Kỳ vọng: ac_out vẫn giữ 300

    // -- TC4: Kiểm tra luồng phản hồi với ALU (inA) --
    $display("--- TC4: Feedback to ALU ---");
    // Trường hợp này xác nhận ac_out (inA của ALU) luôn sẵn sàng
    display_state("TC4  ");  // Kỳ vọng: ac_out = 300 

    // -- TC5: Kiểm tra tương tác với Bus dữ liệu (Lệnh STO) --
    $display("--- TC5: Interaction with Data Bus ---");
    // Mô phỏng việc nạp giá trị mới để chuẩn bị ghi vào Memory
    ld_ac   = 1;
    data_in = 32'd500;
    display_state("TC5.1");  // Kỳ vọng: ac_out = 500 
    ld_ac = 0;
    display_state("TC5.2");  // Giữ giá trị ổn định trong suốt chu kỳ ghi

    // -- TC6: Reset Priority (Ưu tiên Reset khi đang nạp) --
    $display("--- TC6: Reset Priority Check ---");
    ld_ac = 1;
    data_in = 32'd4444;
    rst = 1;  // Kích hoạt Reset cùng lúc với lệnh nạp
    display_state("TC6.1");  // Kỳ vọng: ac_out = 0 (Reset thắng)
    rst = 0;
    display_state("TC6.2");  // Kỳ vọng: ac_out = 4444 (Nạp lại bình thường)

    // -- TC7: Boundary Values (Giá trị biên 32-bit) --
    $display("--- TC7: Boundary Values ---");
    ld_ac   = 1;
    data_in = 32'hFFFF_FFFF;  // Tất cả bit 1
    display_state("TC7.1");
    data_in = 32'h0000_0000;  // Tất cả bit 0
    display_state("TC7.2");

    // -- TC8: Stress Test (Chuyển mạch liên tục) --
    $display("--- TC8: Rapid Toggling ---");
    ld_ac   = 1;
    data_in = 32'hAAAA_AAAA;
    display_state("TC8.1");
    data_in = 32'h5555_5555;
    display_state("TC8.2");
    ld_ac   = 0;
    data_in = 32'h1234_5678;
    display_state("TC8.3");  // Kỳ vọng: Giữ 5555_5555

    $display("--- DONE ---");
    $finish;
  end
endmodule

