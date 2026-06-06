module Memory (
    input       clk,
    input       rd,
    input       wr,
    input [4:0] addr,
    inout [7:0] data
);

  reg [7:0] mem_cells[31:0];
  reg [7:0] data_out;

  always @(posedge clk) begin
    if (wr && !rd) begin
      mem_cells[addr] <= data;
    end else if (rd && !wr) begin
      data_out <= mem_cells[addr];
    end
  end

  assign data = (rd && !wr) ? data_out : 8'hZZ;

endmodule
