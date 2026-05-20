module instruction_register (
    input clk,
    input rst,
    input ld_ir,   
    input [31:0] data_in,  
    output [2:0] opcode,  
    output [4:0] operand   
);

    // 1. TODO: Declare an internal register to store the instruction data
    // 2. TODO: Implement a sequential logic block triggered by the positive edge of the clock
    // 3. TODO: Implement synchronous active-high reset to clear the register
    // 4. TODO: Implement logic to load data_in into the register when ld_ir is active
    // 5. TODO: Implement combinational logic to extract the 3-bit opcode from the stored instruction
    // 6. TODO: Implement combinational logic to extract the 5-bit operand from the stored instruction

endmodule
