module memory (
    input       clk,
    input       rd,
    input       wr,
    input [4:0] addr,
    inout [7:0] data
);

  // 1. TODO: Declare a 2D array of registers to represent memory cells (32 cells of 8 bits)
  reg [7:0] mem_cells[31:0];

  // 2. TODO: Declare a register to hold the output data
  reg [7:0] data_out;

  // 3. TODO: Implement a sequential logic block triggered by the positive edge of the clock for writing data
  always @(posedge clk) begin
    // 4. TODO: Ensure writing only occurs when wr is active and rd is inactive
    if (wr && !rd) begin
      mem_cells[addr] <= data;
    end else
    // 6. TODO: Ensure reading only occurs when rd is active and wr is inactive
    if (rd && !wr) begin
      data_out <= mem_cells[addr];
    end
  end

  // 7. TODO: Implement tri-state buffer logic for the bidirectional data bus
  assign data = (rd && !wr) ? data_out : 8'hZZ;

endmodule
