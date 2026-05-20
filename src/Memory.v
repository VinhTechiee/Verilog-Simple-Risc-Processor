module memory (
    input clk,
    input rd,
    input wr,
    input [31:0] addr, 
    inout [31:0] data  
);

    // 1. TODO: Declare a 2D array of registers to represent memory cells (e.g., 32 cells of 32 bits)
    // 2. TODO: Declare a register to hold the output data
    // 3. TODO: Implement a sequential logic block triggered by the positive edge of the clock for writing data
    // 4. TODO: Ensure writing only occurs when wr is active and rd is inactive
    // 5. TODO: Implement a sequential logic block triggered by the positive edge of the clock for reading data
    // 6. TODO: Ensure reading only occurs when rd is active and wr is inactive
    // 7. TODO: Implement tri-state buffer logic for the bidirectional data bus

endmodule
