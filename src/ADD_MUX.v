module address_mux #(
    parameter WIDTH = 5
) (
    input  [WIDTH-1:0] pc_addr,
    input  [WIDTH-1:0] ir_addr,
    input              sel,
    output [WIDTH-1:0] addr_out
);
 

    assign addr_out = (sel) ? pc_addr : ir_addr;

endmodule
