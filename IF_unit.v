module IF_unit(
    input clk,
    input[31:0] branchPC,
    input isBranchTaken,
    output reg[31:0] PC
);
    always@(posedge clk)
        begin
            if(isBranchTaken) PC=branchPC;
            else PC=PC+1;
        end
endmodule