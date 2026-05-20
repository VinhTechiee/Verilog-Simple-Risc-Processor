module address_mux #(
    parameter WIDTH = 32 
)(
    input [WIDTH-1:0] pc_addr, 
    input [WIDTH-1:0] ir_addr,
    input sel, 
    output [WIDTH-1:0] addr_out 
);
    // 1. TODO: Implement combinational logic to select between pc_addr and ir_addr based on the sel signal
    // 2. TODO: Output pc_addr when sel is 1, and ir_addr when sel is 0
endmodule
