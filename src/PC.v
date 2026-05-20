module PC(
    input clk,
    input rst,
    input ld_pc,
    input inc_pc,
    input [31:0] data_in,
    output reg [31:0] pc_out
    );
    // 1. TODO: Implement a sequential logic block triggered by the positive edge of the clock
    // 2. TODO: Implement synchronous active-high reset to clear the program counter
    // 3. TODO: Implement logic to load a new address into the program counter when ld_pc is active
    // 4. TODO: Implement logic to increment the program counter when inc_pc is active
endmodule
