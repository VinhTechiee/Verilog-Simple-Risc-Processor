module PC (
    input            clk,
    input            rst,
    input            ld_pc,
    input            inc_pc,
    input      [4:0] data_in,
    output reg [4:0] pc_out
);

  always @(posedge clk) begin
    if (rst) begin
      pc_out <= 5'd0;
    end else if (ld_pc) begin
      pc_out <= data_in;
    end else if (inc_pc) begin
      pc_out <= pc_out + 5'd1;
    end else begin
      pc_out <= pc_out;
    end
  end

endmodule
