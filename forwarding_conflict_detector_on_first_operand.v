module forwarding_conflict_detector_on_first_operand(
    input[31:0] instruction_A,
    input[31:0] instruction_B,
    output reg conflict
);
    /* 1 */     parameter opcode_add = 5'b00000;
    /* 2 */     parameter opcode_sub = 5'b00001;
    /* 3 */     parameter opcode_mul = 5'b00010;
    /* 4 */     parameter opcode_div = 5'b00011;
    /* 5 */     parameter opcode_mod = 5'b00100;
    /* 6 */     parameter opcode_cmp = 5'b00101;
    /* 7 */     parameter opcode_and = 5'b00110;
    /* 8 */     parameter opcode_or = 5'b00111;
    /* 9 */     parameter opcode_not = 5'b01000;
    /* 10 */    parameter opcode_mov = 5'b01001;
    /* 11 */    parameter opcode_lsl = 5'b01010;
    /* 12 */    parameter opcode_lsr = 5'b01011;
    /* 13 */    parameter opcode_asr = 5'b01100;
    /* 14 */    parameter opcode_nop = 5'b01101;
    /* 15 */    parameter opcode_ld = 5'b01110;
    /* 16 */    parameter opcode_st = 5'b01111;
    /* 17 */    parameter opcode_beq = 5'b10000;
    /* 18 */    parameter opcode_bgt = 5'b10001;
    /* 19 */    parameter opcode_b = 5'b10010;
    /* 20 */    parameter opcode_call = 5'b10011;
    /* 21 */    parameter opcode_ret = 5'b10100;

    wire[4:0] opcode_A = instruction_A[31:27];
    wire[3:0] rs1_A = instruction_A[21:18];

    wire[4:0] opcode_B = instruction_B[31:27];
    wire[3:0] rd_B = instruction_B[25:22];

    reg[3:0] src1;
    reg[3:0] dest;

    parameter ra = 4'b1111;

    always@(*)
        begin
            if((opcode_A == opcode_nop || opcode_A == opcode_b || opcode_A == opcode_beq || opcode_A == opcode_bgt || opcode_A == opcode_call || opcode_A == opcode_not || opcode_A == opcode_mov) || (opcode_B == opcode_nop || opcode_B == opcode_cmp || opcode_B == opcode_st || opcode_B == opcode_b || opcode_B == opcode_beq || opcode_B == opcode_bgt || opcode_B == opcode_ret))
                conflict = 0;
            else
                begin
                    if(opcode_A == opcode_ret)
                        src1 = ra;
                    else
                        src1 = rs1_A;

                    if(opcode_B == opcode_call)
                        dest = ra;
                    else
                        dest = rd_B;
                end

            if(src1 == dest)
                conflict = 1;
            else
                conflict = 0;
        end
endmodule