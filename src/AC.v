
    // 1. TODO: Implement a sequential logic block triggered by the positive edge of the clock
    // 2. TODO: Implement synchronous active-high reset to clear the accumulator
    // 3. TODO: Implement logic to load new data into the accumulator when the load signal is active
module accumulator (
input clk,
input rst,
input [7:0] data_in,
input ld_ac,

output reg [7:0] ac_out 
    );
    
    always @(posedge clk) begin
    if (rst) 
    ac_out <= 8'b00000000;
    else if (ld_ac)
    ac_out <= data_in;
    else 
    ac_out <= ac_out;
    end 
endmodule

