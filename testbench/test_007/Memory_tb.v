`timescale 1ns / 1ps

module Memory_tb;
  // -- Tín hiệu kết nối --
  reg         clk;
  reg         rd;
  reg         wr;
  reg  [ 4:0] addr;  // 5-bit address cho 32 o nho [cite: 7]
  wire [31:0] data;  // Bus hai chieu [cite: 106]

  // Tin hieu dieu khien bus tu phia Testbench
  reg  [31:0] data_reg;

  // Logic dieu khien Inout: Chi ghi khi wr=1 va rd=0 [cite: 110, 111]
  assign data = (wr && !rd) ? data_reg : 32'hZZZZ_ZZZZ;

  // -- Khoi tao module Memory (DUT) --
  memory uut (
      .clk (clk),
      .rd  (rd),
      .wr  (wr),
      .addr(addr),
      .data(data)
  );

  // -- Tao xung Clock --
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // -- Task hien thi trang thai --
  task display_state;
    input [8*5:1] tc_name;
    begin
      @(posedge clk);
      #1;  // Doi sau canh len de du lieu on dinh 
      $display("%s | rd=%b | wr=%b | addr=%0d | data=0x%08X", tc_name, rd, wr, addr, data);
    end
  endtask

  initial begin
    // Khoi tao ban dau
    rd = 0;
    wr = 0;
    addr = 0;
    data_reg = 0;
    #10;

    // -- TC1: Kiem tra chuc nang ghi du lieu (Write Data) --
    $display("--- TC1: Write Data ---");
    wr = 1;
    rd = 0;
    addr = 5'd10;
    data_reg = 32'hA5A5_A5A5;
    display_state("TC1.1");  // Ghi vao o nho 10 

    addr = 5'd20;
    data_reg = 32'h1234_5678;
    display_state("TC1.2");  // Ghi vao o nho 20 
    wr = 0;

    // -- TC2: Kiem tra chuc nang doc du lieu (Read Data) --
    $display("--- TC2: Read Data ---");
    wr   = 0;
    rd   = 1;
    addr = 5'd10;
    display_state("TC2.1");  // Ky vong: A5A5_A5A5 
    addr = 5'd20;
    display_state("TC2.2");  // Ky vong: 1234_5678 

    // -- TC3: Kiem tra trang thai tro khang cao (High-Z) --
    $display("--- TC3: High Impedance Check ---");
    wr   = 0;
    rd   = 0;  // Khong doc, khong ghi
    addr = 5'd10;
    display_state("TC3  ");  // Ky vong: data = ZZZZZZZZ 

    // -- TC4: Kiem tra ngan chan xung dot (Conflict Prevention) --
    $display("--- TC4: Conflict Prevention ---");
    // Theo dac ta: Khong duoc phep ghi va doc cung luc 
    wr = 1;
    rd = 1;
    addr = 5'd10;
    data_reg = 32'hFFFF_FFFF;
    display_state(
        "TC4  ");  // Ky vong: He thong phai xu ly an toan (thuong la giu Z hoac uu tien not ben)

    // -- TC5: Bo sung - Kiem tra tinh kien dinh (Persistence) --
    $display("--- TC5: Data Persistence ---");
    wr   = 0;
    rd   = 1;
    addr = 5'd10;
    display_state("TC5  ");  // Xac nhan du lieu o nho 10 van la A5A5_A5A5 sau xung dot

    $display("--- DONE ---");
    $finish;
  end
endmodule

