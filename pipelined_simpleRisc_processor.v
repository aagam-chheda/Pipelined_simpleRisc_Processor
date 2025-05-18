`include "forwarding_conflict_detector_on_first_operand.v"
`include "forwarding_conflict_detector_on_second_operand.v"

module pipelined_simpleRisc_processor(
    input clk1,
    input clk2
);
    // Opcodes for the instructions
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

    reg[31:0] reg_file [0:15]; // 16 registers
    reg[31:0] instruction_memory [0:1023]; // 1024 instructions
    reg[31:0] data_memory [0:1023]; // 1024 data memory locations

    // IF_OF pipeline registers
    reg[31:0] IF_OF_PC;
    reg[31:0] IF_OF_instruction;

    // OF_EX pipeline registers
    reg[31:0] OF_EX_PC;
    reg[31:0] OF_EX_branchTarget;
    reg[31:0] OF_EX_A;
    reg[31:0] OF_EX_B;
    reg[31:0] OF_EX_op2;
    reg[31:0] OF_EX_instruction;
    reg[21:0] OF_EX_control_signals;

    // EX stage flags
    reg flags_E, flags_GT;

    // EX_MA pipeline registers
    reg[31:0] EX_MA_PC;
    reg[31:0] EX_MA_aluResult;
    reg[31:0] EX_MA_op2;
    reg[31:0] EX_MA_instruction;
    reg[21:0] EX_MA_control_signals;
    reg[31:0] EX_MA_branch;
    reg EX_MA_isBranchTaken;

    // MA_RW pipeline registers
    reg[31:0] MA_RW_PC;
    reg[31:0] MA_RW_ldResult;
    reg[31:0] MA_RW_aluResult;
    reg[31:0] MA_RW_instruction;
    reg[21:0] MA_RW_control_signals;
    
    // Forwarding Unit Control Signals Starts
    // Control signals for Forwarding
    reg M1;
    reg M2;
    reg[1:0] M3;
    reg[1:0] M4;
    reg M5;
    reg M6;

    wire forwarding_conflict_on_first_operand_RW_to_MA;
    wire forwarding_conflict_on_first_operand_RW_to_EX;
    wire forwarding_conflict_on_first_operand_MA_to_EX;
    wire forwarding_conflict_on_first_operand_RW_to_OF;

    wire forwarding_conflict_on_second_operand_RW_to_MA;
    wire forwarding_conflict_on_second_operand_RW_to_EX;
    wire forwarding_conflict_on_second_operand_MA_to_EX;
    wire forwarding_conflict_on_second_operand_RW_to_OF;

    forwarding_conflict_detector_on_first_operand forwarding_conflict_detector_on_first_operand_RW_to_MA_detector(EX_MA_instruction, MA_RW_instruction, forwarding_conflict_on_first_operand_RW_to_MA);
    forwarding_conflict_detector_on_first_operand forwarding_conflict_detector_on_first_operand_RW_to_EX_detector(OF_EX_instruction, MA_RW_instruction, forwarding_conflict_on_first_operand_RW_to_EX);
    forwarding_conflict_detector_on_first_operand forwarding_conflict_detector_on_first_operand_MA_to_EX_detector(OF_EX_instruction, EX_MA_instruction, forwarding_conflict_on_first_operand_MA_to_EX);
    forwarding_conflict_detector_on_first_operand forwarding_conflict_detector_on_first_operand_RW_to_OF_detector(IF_OF_instruction, MA_RW_instruction, forwarding_conflict_on_first_operand_RW_to_OF);

    forwarding_conflict_detector_on_second_operand forwarding_conflict_detector_on_second_operand_RW_to_MA_detector(EX_MA_instruction, MA_RW_instruction, forwarding_conflict_on_second_operand_RW_to_MA);
    forwarding_conflict_detector_on_second_operand forwarding_conflict_detector_on_second_operand_RW_to_EX_detector(OF_EX_instruction, MA_RW_instruction, forwarding_conflict_on_second_operand_RW_to_EX);
    forwarding_conflict_detector_on_second_operand forwarding_conflict_detector_on_second_operand_MA_to_EX_detector(OF_EX_instruction, EX_MA_instruction, forwarding_conflict_on_second_operand_MA_to_EX);
    forwarding_conflict_detector_on_second_operand forwarding_conflict_detector_on_second_operand_RW_to_OF_detector(IF_OF_instruction, MA_RW_instruction, forwarding_conflict_on_second_operand_RW_to_OF);

    always@(*)      // Forwarding control signals for OF stage
        begin
            if(forwarding_conflict_on_first_operand_RW_to_OF)
                M1 = 1;
            else
                M1 = 0;

            if(forwarding_conflict_on_second_operand_RW_to_OF)
                M2 = 1;
            else
                M2 = 0;
        end

    always@(*)      // Forwarding control signals for EX stage
        begin
            if(forwarding_conflict_on_first_operand_MA_to_EX)
                M3 = 2'b10;
            else if(forwarding_conflict_on_first_operand_RW_to_EX)
                M3 = 2'b01;
            else
                M3 = 2'b00;

            if(forwarding_conflict_on_second_operand_MA_to_EX)
                M4 = 2'b10;
            else if(forwarding_conflict_on_second_operand_RW_to_EX)
                M4 = 2'b01;
            else
                M4 = 2'b00;
        end

    always@(*)      // Forwarding control signals for MA stage
        begin
            if(forwarding_conflict_on_second_operand_RW_to_MA)
                M6 = 1;
            else
                M6 = 0;
        end
    // Forwarding Unit Control Signals Ends

    wire[31:0] data_effective;
    assign data_effective = ({MA_RW_control_signals[13], MA_RW_control_signals[20]}==2'b00) ? MA_RW_aluResult :
                            ({MA_RW_control_signals[13], MA_RW_control_signals[20]}==2'b01) ? MA_RW_ldResult :
                            ({MA_RW_control_signals[13], MA_RW_control_signals[20]}==2'b10) ? MA_RW_PC + 1 : 32'b0;
                            
    wire[31:0] alu_A_after_implementing_forwarding;
    wire[31:0] alu_B_after_implementing_forwarding;
    assign alu_A_after_implementing_forwarding = (M3 == 00) ? OF_EX_A :
                             (M3 == 01) ? data_effective : EX_MA_aluResult;
    assign alu_B_after_implementing_forwarding = (M4 == 00) ? OF_EX_B :
                             (M4 == 01) ? data_effective : EX_MA_aluResult;

    always@(posedge clk1)       // IF stage
        begin
            if(EX_MA_isBranchTaken)
                IF_OF_PC <= EX_MA_branch;
            else
                IF_OF_PC <= IF_OF_PC + 1;

            IF_OF_instruction <= instruction_memory[IF_OF_PC];            
        end

    always@(posedge clk2)       // OF stage
        begin
            OF_EX_PC <= IF_OF_PC;
            OF_EX_instruction <= IF_OF_instruction;

            /*isSt*/         OF_EX_control_signals[21] <= !IF_OF_instruction[31] & IF_OF_instruction[30] & IF_OF_instruction[29] & IF_OF_instruction[28] & IF_OF_instruction[27];
            /*isLd*/         OF_EX_control_signals[20] <= !IF_OF_instruction[31] & IF_OF_instruction[30] & IF_OF_instruction[29] & IF_OF_instruction[28] & !IF_OF_instruction[27];
            /*isBeq*/        OF_EX_control_signals[19] <= IF_OF_instruction[31] & !IF_OF_instruction[30] & !IF_OF_instruction[29] & !IF_OF_instruction[28] & !IF_OF_instruction[27];
            /*isBgt*/        OF_EX_control_signals[18] <= IF_OF_instruction[31] & !IF_OF_instruction[30] & !IF_OF_instruction[29] & !IF_OF_instruction[28] & IF_OF_instruction[27];
            /*isRet*/        OF_EX_control_signals[17] <= IF_OF_instruction[31] & !IF_OF_instruction[30] & IF_OF_instruction[29] & !IF_OF_instruction[28] & !IF_OF_instruction[27];
            /*isImmediate*/  OF_EX_control_signals[16] <= IF_OF_instruction[26];
            /*isWb*/         OF_EX_control_signals[15] <= !(IF_OF_instruction[31] | !IF_OF_instruction[31]&IF_OF_instruction[29]&IF_OF_instruction[27]&(IF_OF_instruction[30]|!IF_OF_instruction[28])) | (IF_OF_instruction[31] & !IF_OF_instruction[30] & !IF_OF_instruction[29] & IF_OF_instruction[28] & IF_OF_instruction[27]);
            /*isUBranch*/    OF_EX_control_signals[14] <= IF_OF_instruction[31]&!IF_OF_instruction[30]&(!IF_OF_instruction[29]&IF_OF_instruction[28] | IF_OF_instruction[29]&!IF_OF_instruction[28]&IF_OF_instruction[27]);
            /*isCall*/       OF_EX_control_signals[13] <= IF_OF_instruction[31] & !IF_OF_instruction[30] & !IF_OF_instruction[29] & IF_OF_instruction[28] & IF_OF_instruction[27];
            /*isAdd*/        OF_EX_control_signals[12] <= (!IF_OF_instruction[31] & !IF_OF_instruction[30] & !IF_OF_instruction[29] & !IF_OF_instruction[28] & !IF_OF_instruction[27])|(!IF_OF_instruction[31] & IF_OF_instruction[30] & IF_OF_instruction[29] & IF_OF_instruction[28]);
            /*isSub*/        OF_EX_control_signals[11] <= !IF_OF_instruction[31] & !IF_OF_instruction[30] & !IF_OF_instruction[29] & !IF_OF_instruction[28] & IF_OF_instruction[27];
            /*isCmp*/        OF_EX_control_signals[10] <= !IF_OF_instruction[31] & !IF_OF_instruction[30] & IF_OF_instruction[29] & !IF_OF_instruction[28] & IF_OF_instruction[27];
            /*isMul*/        OF_EX_control_signals[9] <= !IF_OF_instruction[31] & !IF_OF_instruction[30] & !IF_OF_instruction[29] & IF_OF_instruction[28] & !IF_OF_instruction[27];
            /*isDiv*/        OF_EX_control_signals[8] <= !IF_OF_instruction[31] & !IF_OF_instruction[30] & !IF_OF_instruction[29] & IF_OF_instruction[28] & IF_OF_instruction[27];
            /*isMod*/        OF_EX_control_signals[7] <= !IF_OF_instruction[31] & !IF_OF_instruction[30] & IF_OF_instruction[29] & !IF_OF_instruction[28] & !IF_OF_instruction[27];
            /*isLsl*/        OF_EX_control_signals[6] <= !IF_OF_instruction[31] & IF_OF_instruction[30] & !IF_OF_instruction[29] & IF_OF_instruction[28] & !IF_OF_instruction[27];
            /*isLsr*/        OF_EX_control_signals[5] <= !IF_OF_instruction[31] & IF_OF_instruction[30] & !IF_OF_instruction[29] & IF_OF_instruction[28] & IF_OF_instruction[27];
            /*isAsr*/        OF_EX_control_signals[4] <= !IF_OF_instruction[31] & IF_OF_instruction[30] & IF_OF_instruction[29] & !IF_OF_instruction[28] & !IF_OF_instruction[27];
            /*isOr*/         OF_EX_control_signals[3] <= !IF_OF_instruction[31] & !IF_OF_instruction[30] & IF_OF_instruction[29] & IF_OF_instruction[28] & IF_OF_instruction[27];
            /*isAnd*/        OF_EX_control_signals[2] <= !IF_OF_instruction[31] & !IF_OF_instruction[30] & IF_OF_instruction[29] & IF_OF_instruction[28] & !IF_OF_instruction[27];
            /*isNot*/        OF_EX_control_signals[1] <= !IF_OF_instruction[31] & IF_OF_instruction[30] & !IF_OF_instruction[29] & !IF_OF_instruction[28] & !IF_OF_instruction[27];
            /*isMov*/        OF_EX_control_signals[0] <= !IF_OF_instruction[31] & IF_OF_instruction[30] & !IF_OF_instruction[29] & !IF_OF_instruction[28] & IF_OF_instruction[27];

            OF_EX_branchTarget <= {{5{IF_OF_instruction[26]}},IF_OF_instruction[26:0]} + IF_OF_PC;

            if(M1)
                OF_EX_A <= data_effective;
            else
                OF_EX_A <= (IF_OF_instruction[31:27] == opcode_ret) ? reg_file[15] : reg_file[IF_OF_instruction[21:18]];

            OF_EX_op2 <= (IF_OF_instruction[31:27] == opcode_st) ? reg_file[IF_OF_instruction[25:22]] : reg_file[IF_OF_instruction[17:14]];

            if(M2)
                OF_EX_B <= data_effective;
            else
                begin
                    if(IF_OF_instruction[26])
                        begin
                            case(IF_OF_instruction[17:16])
                                2'b01: OF_EX_B <= {16'b0,IF_OF_instruction[15:0]}; // u-modified immediate
                                2'b10: OF_EX_B <= {IF_OF_instruction[15:0],16'b0}; // h-modified immediate
                                default: OF_EX_B <= {{16{IF_OF_instruction[15]}},IF_OF_instruction[15:0]};
                            endcase
                        end
                    else
                        OF_EX_B <= (IF_OF_instruction[31:27] == opcode_st) ? reg_file[IF_OF_instruction[25:22]] : reg_file[IF_OF_instruction[17:14]];
                end
        end

    always@(posedge clk1)       // EX stage
        begin
            EX_MA_PC <= OF_EX_PC;
            EX_MA_instruction <= OF_EX_instruction;
            EX_MA_control_signals <= OF_EX_control_signals;

            EX_MA_op2 <= (M5) ? MA_RW_ldResult : OF_EX_op2;

            EX_MA_branch <= (OF_EX_control_signals[17]) ? alu_A_after_implementing_forwarding : OF_EX_branchTarget;

            EX_MA_isBranchTaken <= (OF_EX_control_signals[19] & (alu_A_after_implementing_forwarding == alu_B_after_implementing_forwarding)) | (OF_EX_control_signals[18] & (alu_A_after_implementing_forwarding > alu_B_after_implementing_forwarding)) | (OF_EX_control_signals[14]);

            flags_E <= (OF_EX_control_signals[10]) ? (alu_A_after_implementing_forwarding == alu_B_after_implementing_forwarding) : 1'b0;
            flags_GT <= (OF_EX_control_signals[10]) ? (alu_A_after_implementing_forwarding > alu_B_after_implementing_forwarding) : 1'b0;

            EX_MA_aluResult <= (OF_EX_control_signals[12]) ? alu_A_after_implementing_forwarding + alu_B_after_implementing_forwarding :
                               (OF_EX_control_signals[11]) ? alu_A_after_implementing_forwarding - alu_B_after_implementing_forwarding :
                               (OF_EX_control_signals[9]) ? alu_A_after_implementing_forwarding * alu_B_after_implementing_forwarding :
                               (OF_EX_control_signals[8]) ? alu_A_after_implementing_forwarding / alu_B_after_implementing_forwarding :
                               (OF_EX_control_signals[7]) ? alu_A_after_implementing_forwarding % alu_B_after_implementing_forwarding :
                               (OF_EX_control_signals[6]) ? alu_A_after_implementing_forwarding << alu_B_after_implementing_forwarding :
                               (OF_EX_control_signals[5]) ? alu_A_after_implementing_forwarding >> alu_B_after_implementing_forwarding :
                               (OF_EX_control_signals[4]) ? alu_A_after_implementing_forwarding >>> alu_B_after_implementing_forwarding :
                               (OF_EX_control_signals[3]) ? alu_A_after_implementing_forwarding | alu_B_after_implementing_forwarding :
                               (OF_EX_control_signals[2]) ? alu_A_after_implementing_forwarding & alu_B_after_implementing_forwarding :
                               (OF_EX_control_signals[1]) ? ~alu_B_after_implementing_forwarding :
                               (OF_EX_control_signals[0]) ? alu_B_after_implementing_forwarding : 32'b0;
        end

    always@(posedge clk2)       // MA stage
        begin
            MA_RW_PC <= EX_MA_PC;
            MA_RW_aluResult <= EX_MA_aluResult;
            MA_RW_instruction <= EX_MA_instruction;
            MA_RW_control_signals <= EX_MA_control_signals;

            if(EX_MA_control_signals[20])
                MA_RW_ldResult <= data_memory[EX_MA_aluResult];
            else
                MA_RW_ldResult <= 32'b0;

            if(EX_MA_control_signals[21])
                data_memory[EX_MA_aluResult] <= (M6) ? data_effective : EX_MA_op2;
            else
                data_memory[EX_MA_aluResult] <= data_memory[EX_MA_aluResult];
        end

    always@(posedge clk1)       // RW stage
        begin
            if(MA_RW_control_signals[15])
                begin
                    if(MA_RW_control_signals[13])
                        reg_file[15] <= data_effective;
                    else
                        reg_file[MA_RW_instruction[25:22]] <= data_effective;
                end
            else
                begin
                    if(MA_RW_control_signals[13])
                        reg_file[15] <= reg_file[15];
                    else
                        reg_file[MA_RW_instruction[25:22]] <= reg_file[MA_RW_instruction[25:22]];
                end
        end
endmodule