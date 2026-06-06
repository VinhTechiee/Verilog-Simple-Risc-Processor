module accumulator (
    input            clk,
    input            rst,
    input      [7:0] data_in,
    input            ld_ac,
    output reg [7:0] ac_out
);

  always @(posedge clk) begin
    if (rst) ac_out <= 8'b00000000;
    else if (ld_ac) ac_out <= data_in;
    else ac_out <= ac_out;
  end

endmodule
