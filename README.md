# HƯỚNG DẪN BÀI TẬP LỚN HK252
**Phiên bản 1.0**

## 1. Yêu cầu về kiến thức
* Thiết kế Module Verilog bằng mô hình RTL, mô hình Hành vi.
* Biểu diễn được máy FSM bằng mã nguồn Verilog.
* Kiến thức về Parameter, Memory.

## 2. Lý thuyết
Dựa trên đặc tả, RISC CPU trong bài tập lớn này sẽ có 3-bit opcode và 5-bit toán hạng, tức là có 8 loại câu lệnh và 32 không gian địa chỉ. Bộ xử lý hoạt động dựa trên tín hiệu clock và reset. Chương trình sẽ dừng lại khi có tín hiệu HALT.

Thông qua bảng trạng thái và các chức năng của các khối trong đặc tả, có thể chia luồng hoạt động của CPU thành 2 giai đoạn chính như sau: Giai đoạn nạp lệnh và Giai đoạn thực thi.

| Outputs | INST_ADDR | INST_FETCH | INST_LOAD | IDLE | OP_ADDR | OP_FETCH | ALU_OP | STORE | Notes |
|---|---|---|---|---|---|---|---|---|---|
| sel | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | ALU OP = 1 if opcode is ADD, AND, XOR or LDA |
| rd | 0 | 1 | 1 | 1 | 0 | ALUOP | ALUOP | ALUOP | |
| ld_ir | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | |
| halt | 0 | 0 | 0 | 0 | HALT | 0 | 0 | 0 | |
| inc_pc | 0 | 0 | 0 | 0 | 1 | 0 | SKZ && zero | 0 | |
| ld_ac | 0 | 0 | 0 | 0 | 0 | 0 | 0 | ALUOP | |
| ld_pc | 0 | 0 | 0 | 0 | 0 | 0 | JMP | JMP | |
| wr | 0 | 0 | 0 | 0 | 0 | 0 | 0 | STO | |
| data_e | 0 | 0 | 0 | 0 | 0 | 0 | STO | STO | |

### 2.1 Giai đoạn nạp lệnh
* **GĐ 1: INST_ADDR.** Program counter (PC) cung cấp địa chỉ của câu lệnh. Khối Address Mux sẽ chọn địa chỉ từ PC (`sel = 1`) để truy xuất vào bộ nhớ.
* **GĐ 2: INST_FETCH.** Tín hiệu đọc bộ nhớ (`rd = 1`) được kích hoạt. Dữ liệu câu lệnh được lấy từ Memory.
* **GĐ 3: INST_LOAD.** Câu lệnh vừa lấy về được nạp vào Instruction Register (IR).
* **GĐ 4: IDLE.** Trạng thái chờ trung gian của hệ thống.

### 2.2 Giai đoạn thực thi
* **GĐ 5: OP_ADDR.** IR sẽ tách câu lệnh thành Opcode (3-bit) và Địa chỉ toán hạng (5-bit). Address Mux lúc này sẽ chọn địa chỉ toán hạng từ IR (tín hiệu `sel = 0`) thay vì từ PC.
* **GĐ 6: OP_FETCH.** Nếu lệnh cần dữ liệu từ bộ nhớ (như ADD, AND, LDA...), CPU sẽ đọc dữ liệu từ địa chỉ toán hạng trong Memory.
* **GĐ 7: ALU_OP.** Khối ALU thực hiện tính toán giữa dữ liệu từ Memory và dữ liệu đang có trong Accumulator (AC) dựa trên mã Opcode nhận được.
* **GĐ 8: STORE.** Kết quả sau khi tính toán sẽ được lưu trữ ngược lại vào Memory (nếu là lệnh STO) hoặc nạp vào Accumulator (nếu là các lệnh tính toán). Sau đó, bộ đếm chương trình PC sẽ tăng lên (`inc_pc`) để chuẩn bị cho câu lệnh tiếp theo.

## 3. Thiết kế hệ thống
### 3.1 Sơ đồ khối
Update later...

### 3.2 Các khối chức năng

#### Program Counter
* **Chức năng:**
  * Counter là bộ đếm quan trọng dùng để đếm câu lệnh của chương trình.
  * Ngoài ra còn có thể dùng đếm các trạng thái của chương trình.
  * Counter phải hoạt động khi có xung lên của `clk`.
  * Reset kích hoạt mức cao, bộ đếm trở về 0.
  * Counter với độ rộng số đếm là 32.
  * Counter có chức năng load một số bất kỳ vào bộ đếm. Nếu không, bộ đếm sẽ hoạt động bình thường.
* **Input:** clock, reset, ld_pc, inc_pc, data_in.
* **Output:** pc_out.
* **Thiết kế module testbench với các trường hợp cơ bản:**
  * *Trường hợp 1:* Kiểm tra chức năng reset.
  * *Trường hợp 2:* Kiểm tra chức năng đếm lên của PC.
  * *Trường hợp 3:* Kiểm tra chức năng nạp (load) địa chỉ câu lệnh của PC.
  * *Trường hợp 4:* Kiểm tra thứ tự ưu tiên giữa 3 lệnh: `rst`, `ld_pc`, `inc_pc` (xác định mức ưu tiên khi cả 3 tín hiệu đều bằng 1).

#### Address Mux
* **Chức năng:**
  * Khối Address Mux với chức năng của Mux sẽ chọn giữa địa chỉ lệnh trong giai đoạn nạp lệnh và địa chỉ toán hạng trong giai đoạn thực thi lệnh.
  * Mux sẽ có độ rộng mặc định là 32.
  * Độ rộng cần sử dụng parameter để vẫn thay đổi được nếu cần.
* **Input:** pc_add, ir_add, sel.
* **Output:** add_out.
* **Thiết kế module testbench với các trường hợp cơ bản:**
  * *Trường hợp 1:* Kiểm tra lựa chọn địa chỉ lệnh (`sel = 1`).
  * *Trường hợp 2:* Kiểm tra lựa chọn địa chỉ toán hạng (`sel = 0`).
  * *Trường hợp 3:* Kiểm tra sự thay đổi của đầu ra khi thay đổi tín hiệu sel liên tiếp.
  * *Trường hợp 4:* Kiểm tra sự thay đổi của parameter.

#### ALU
* **Chức năng:**
  * ALU thực thi những phép toán số học. Phép tính được thực thi sẽ phụ thuộc vào toán tử của câu lệnh.
  * ALU thực thi 8 phép toán trên số hạng 32-bit (`inA` và `inB`).
  * Kết quả sẽ cho ra 32-bit output và 1-bit `is_zero`.
  * `is_zero` bất đồng bộ nhằm cho biết input `inA` có bằng 0 hay không.
* **Bảng tra cứu Opcode:**

| Opcode | Mã | Hoạt động | Output |
|---|---|---|---|
| HLT | 000 | Dừng hoạt động chương trình | inA |
| SKZ | 001 | Trước tiên sẽ kiểm tra kết quả của ALU có bằng 0 hay không, nếu bằng 0 thì sẽ bỏ qua câu lệnh tiếp theo, ngược lại sẽ tiếp tục thực thi như bình thường | inA |
| ADD | 010 | Cộng giá trị trong Accumulator vào giá trị bộ nhớ địa chỉ trong câu lệnh và kết quả được trả về Accumulator. | inA+inB |
| AND | 011 | Thực hiện AND giá trị trong Accumulator và giá trị bộ nhớ địa chỉ trong câu lệnh và kết quả được trả về Accumulator. | inA and inB |
| XOR | 100 | Thực hiện XOR giá trị trong Accumulator và giá trị bộ nhớ địa chỉ trong câu lệnh và kết quả được trả về Accumulator. | inA or inB |
| LDA | 101 | Thực hiện đọc giá trị từ địa chỉ trong câu lệnh và đưa vào Accumulator. | inB |
| STO | 110 | Thực hiện ghi dữ liệu của Accumulator vào địa chỉ trong câu lệnh. | inA |
| JMP | 111 | Lệnh nhảy không điều kiện, nhảy đến địa chỉ đích trong câu lệnh và tiếp tục thực hiện chương trình | inA |

* **Input:** inA, inB, opcode.
* **Output:** alu_out, zero.
* **Thiết kế module testbench với các trường hợp cơ bản:**
  * *Trường hợp 1:* Kiểm tra tín hiệu trạng thái Zero.
  * *Trường hợp 2:* Kiểm tra các phép tính số học (ADD, AND, XOR, LDA).
  * *Trường hợp 3:* Kiểm tra các lệnh chuyển tiếp (HLT, SKZ, STO, JMP).
  * *Trường hợp 4:* Kiểm tra tính tổ hợp: alu_out phải cập nhật giá trị mới ngay lập tức (không phải đợi cạnh lên của clock).

#### Controller
* **Input:** clk, rst, opcode, zero.
* **Output:** sel, rd, ld_ir, halt, inc_pc, ld_ac, ld_pc, wr, data_e.
* **Thiết kế module testbench với các trường hợp cơ bản:**
  * *Trường hợp 1:* Kiểm tra reset hệ thống.
  * *Trường hợp 2:* Kiểm tra trình tự chuyển đổi trạng thái.
  * *Trường hợp 3:* Kiểm tra giai đoạn Nạp lệnh: Quan sát các tín hiệu tại INST_ADDR, INST_FETCH, INST_LOAD, và IDLE.
  * *Trường hợp 4:* Kiểm tra giai đoạn thực thi lệnh: kiểm tra các tín hiệu đầu ra tại các trạng thái từ OP_ADDR đến STORE ứng với từng Opcode cụ thể.

**Kịch bản điều khiển theo mã lệnh**

| Kịch bản lệnh | Trạng thái | Tín hiệu kỳ vọng |
|---|---|---|
| HLT (000) | OP_ADDR | halt = 1 |
| ADD, AND, XOR, LDA | OP_FETCH đến STORE | rd = 1, ld_ac = 1 (tại pha STORE) |
| STO (110) | ALU_OP, STORE | wr = 1, data_e = 1 |
| JMP (111) | ALU_OP, STORE | ld_pc = 1 |

  * *Trường hợp 5:* Kiểm tra logic nhảy có điều kiện: kiểm tra 2 tín hiệu opcode (SKZ) và zero để xem tín hiệu inc_pc có hoạt động đúng logic không.
  * *Trường hợp 6:* Kiểm tra tính đồng bộ của tín hiệu: sự đồng bộ tín hiệu của ld_ir, ld_ac, wr.

#### Instruction register
* **Chức năng:** (được mô tả trong tài liệu tham khảo)
* **Input:** clk, rst, ld_ir, data_in
* **Output:** opcode, operand.
* **Thiết kế module testbench cho các trường hợp cơ bản sau:**
  * *Trường hợp 1:* kiểm tra chức năng reset của hệ thống.
  * *Trường hợp 2:* kiểm tra chức năng nạp lệnh.
  * *Trường hợp 3:* Kiểm tra chức năng giữ giá trị. Xác nhận logic giữ giá trị khi tín hiệu ld_ir không được kích hoạt.
  * *Trường hợp 4:* Kiểm tra chức năng Phân tách mã lệnh: chia nhỏ dữ liệu 32-bit thành Opcode và Operand.

#### Accumulator Register
* **Chức năng:** (được mô tả trong tài liệu tham khảo)
* **Input:** clk, rst, ld_ac, data_in
* **Output:** ac_out
* **Thiết kế module testbench cho các trường hợp cơ bản sau:**
  * *Trường hợp 1:* kiểm tra chức năng reset của hệ thống.
  * *Trường hợp 2:* Kiểm tra chức năng nạp dữ liệu: Xác nhận AC có thể lưu kết quả tính toán từ ALU vào đúng thời điểm được chỉ định (đặt ld_ac = 1).
  * *Trường hợp 3:* Kiểm tra tính ổn định dữ liệu: Đảm bảo dữ liệu không bị ghi đè ngoài ý muốn khi CPU đang thực hiện các tác vụ khác như nạp lệnh hoặc giải mã (đặt ld_ac = 0).
  * *Trường hợp 4:* Kiểm tra luồng phản hồi với ALU: Kiểm tra khả năng AC cung cấp dữ liệu làm toán hạng cho ALU (inA).
  * *Trường hợp 5:* Kiểm tra tương tác với Bus dữ liệu: Kiểm tra vai trò của AC khi đóng vai trò là nguồn dữ liệu ghi vào Memory trong lệnh STO.

#### Memory
* **Chức năng:**
  * Memory sẽ lưu trữ instruction và data.
  * Memory cần được thiết kế tách riêng chức năng đọc/ghi bằng cách sử dụng Single bidirectional data port. Không được đọc và ghi cùng lúc.
  * 32-bit địa chỉ và 32-bit data.
  * 1-bit tín hiệu cho phép đọc/ghi.
  * Memory phải hoạt động khi có xung lên của clk.
* **Input:** clk, rd, wr, addr
* **Inout:** data
* **Thiết kế module testbench cho các trường hợp cơ bản sau:**
  * *Trường hợp 1:* Kiểm tra chức năng ghi dữ liệu (write data): Xác nhận bộ nhớ có thể lưu trữ dữ liệu vào đúng ô nhớ tại cạnh lên của xung clock.
  * *Trường hợp 2:* Kiểm tra chức năng đọc dữ liệu (read data): Xác nhận bộ nhớ có thể xuất dữ liệu đã lưu ra bus dữ liệu.
  * *Trường hợp 3:* Kiểm tra trạng thái trở kháng cao: vì module sử dụng cổng dữ liệu hai chiều nên phải kiểm tra trạng thái trở kháng cao (z).
  * *Trường hợp 4:* Kiểm tra ngăn chặn xung đột: không được phép ghi và đọc cùng một lúc (rd = 1, wr = 1).

#### CPU
* **Input:** clk, rst
* **Output:** halt
* **Thiết kế module testbench cho một đoạn chương trình cụ thể nào đó:**

**Ví dụ:** Cho một đoạn chương trình như sau:
```assembly
LDA 20
ADD 21
STO 22
HLT
```
Chương trình được nạp vào bộ nhớ từ địa chỉ 0 đến 3. Dữ liệu đầu vào nằm tại các ô nhớ 20 và 21 (Giá trị lần lượt là 5 và 3). Quy trình thực thi được chia thành các giai đoạn dựa trên chu kỳ 8 trạng thái của bộ điều khiển.

*Giải thích chi tiết quy trình thực thi:*
1. **Lệnh LDA 20 (Nạp giá trị tại ô nhớ 20 vào AC):**
   * Giai đoạn INST (GD 0-3): CPU truy xuất địa chỉ 0 từ Program Counter (PC), nạp mã lệnh 8'hB4 vào Instruction Register (IR).
   * Giai đoạn EXEC (GD 4-7): Bộ điều khiển giải mã Opcode 101. Address Mux chọn địa chỉ toán hạng 20. Tại pha STORE, giá trị 5 từ bộ nhớ được nạp vào thanh ghi Accumulator (AC).
   * Kết quả: `AC = 5`.

2. **Lệnh ADD 21 (Cộng giá trị tại ô nhớ 21 vào AC):**
   * Giai đoạn INST: CPU nạp mã lệnh 8'h55 từ địa chỉ 1 vào IR; PC tăng lên 2.
   * Giai đoạn EXEC: Opcode 010 được giải mã. ALU thực hiện phép toán số học giữa `inA` (giá trị hiện tại của AC là 5) và `inB` (giá trị từ ô nhớ 21 là 3).
   * Kết quả: Tại pha cuối, giá trị tổng `8` được ghi đè vào AC (`AC = 8`).

3. **Lệnh STO 22 (Lưu kết quả từ AC vào ô nhớ 22):**
   * Giai đoạn INST: CPU nạp mã lệnh 8'hD6 từ địa chỉ 2 vào IR.
   * Giai đoạn EXEC: Giải mã Opcode 110. Tín hiệu `data_e` và `wr` được kích hoạt ở mức cao. Dữ liệu từ AC (8) được đẩy lên bus dữ liệu hai chiều và ghi vào ô nhớ địa chỉ 22.
   * Kết quả: `Mem[22] = 8`.

4. **Lệnh HLT (Dừng hệ thống):**
   * Giai đoạn INST: CPU nạp mã lệnh 8'h00 từ địa chỉ 3.
   * Giai đoạn EXEC: Giải mã Opcode 000. Tín hiệu `halt` được xác lập, CPU ngừng chuyển đổi trạng thái và kết thúc chương trình.

## 4. Các lưu ý
1. Trong folder `src` đã bao gồm các phần hiện thực của các module, các bạn tải về và hiện thực các module. Trong mỗi module đều có hướng dẫn chi tiết, các bạn đọc và hiện thực logic của module. Yêu cầu phải tự viết mã nguồn để hiểu rõ lý thuyết hơn.
2. Các bạn phải tự thực hiện lại mã nguồn của testbench theo các trường hợp trên, đồng thời thêm các trường hợp tự sáng tạo của riêng mình.
3. Sẽ có testbench riêng để kiểm tra lại các khối. Testbench sẽ được update sau.

## 5. Testbench
1. Sử dụng công cụ Vivado sim và Icarus Verilog để mô phỏng.
2. Tải file python. Sử dụng cú pháp như sau trong terminal để chạy test.
* Kiểm tra toàn bộ test (Tự chọn công cụ mô phỏng): ```python run_tests.py --src src --testbench testbench ```
* Kiểm tra toàn bộ test (Chỉ sử dụng Vivado): ```python run_tests.py --src src --testbench testbench --sim vivado --loose```
* Kiểm tra từng test: ```python run_tests.py --src src --testbench testbench --filter test_00x```
3. ...
