module controller(
    input clk,
    input rst,
    input [2:0] opcode,
    input zero, 
    output reg sel, 
    output reg rd,  
    output reg ld_ir, 
    output reg halt, 
    output reg inc_pc, 
    output reg ld_ac, 
    output reg ld_pc, 
    output reg wr,  
    output reg data_e 

    );
    // 1. TODO: Define state parameters for the 8-state FSM
    // 2. TODO: Define opcode parameters for the 8 instructions
    // 3. TODO: Declare a state register
    // 4. TODO: Implement a sequential logic block for FSM state transitions (triggered by posedge clk)
    // 5. TODO: Implement synchronous active-high reset to set the initial state
    // 6. TODO: Implement combinational logic to determine output control signals based on the current state and opcode
    // 7. TODO: Ensure all output signals are assigned a default value to prevent latches
endmodule
