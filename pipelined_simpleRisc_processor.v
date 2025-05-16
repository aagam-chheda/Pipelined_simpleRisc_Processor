module pipelined_simpleRisc_processor(
    input clk1,
    input clk2
);
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

    parameter isSt = 5'b01111;
    parameter isRet = 5'b10100;

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

            OF_EX_A <= (IF_OF_instruction[31:27] == isRet) ? reg_file[15] : reg_file[IF_OF_instruction[21:18]];

            OF_EX_op2 <= (IF_OF_instruction[31:27] == isSt) ? reg_file[IF_OF_instruction[25:22]] : reg_file[IF_OF_instruction[17:14]];

            if(IF_OF_instruction[26])
                begin
                    case(IF_OF_instruction[17:16])
                        2'b01: OF_EX_B <= {16'b0,IF_OF_instruction[15:0]}; // u-modified immediate
                        2'b10: OF_EX_B <= {IF_OF_instruction[15:0],16'b0}; // h-modified immediate
                        default: OF_EX_B <= {{16{IF_OF_instruction[15]}},IF_OF_instruction[15:0]};
                    endcase
                end
            else
                OF_EX_B <= (IF_OF_instruction[31:27] == isSt) ? reg_file[IF_OF_instruction[25:22]] : reg_file[IF_OF_instruction[17:14]];
        end

    always@(posedge clk1)       // EX stage
        begin
            EX_MA_PC <= OF_EX_PC;
            EX_MA_op2 <= OF_EX_op2;
            EX_MA_instruction <= OF_EX_instruction;
            EX_MA_control_signals <= OF_EX_control_signals;

            EX_MA_branch <= (OF_EX_control_signals[17]) ? OF_EX_A : OF_EX_branchTarget;

            EX_MA_isBranchTaken <= (OF_EX_control_signals[19] & (OF_EX_A == OF_EX_B)) | (OF_EX_control_signals[18] & (OF_EX_A > OF_EX_B)) | (OF_EX_control_signals[14]);

            flags_E = (OF_EX_control_signals[10]) ? (OF_EX_A==OF_EX_B) : 1'b0;
            flags_GT = (OF_EX_control_signals[10]) ? (OF_EX_A>OF_EX_B) : 1'b0;

            EX_MA_aluResult = (OF_EX_control_signals[12]) ? OF_EX_A + OF_EX_B :
                              (OF_EX_control_signals[11]) ? OF_EX_A - OF_EX_B :
                              (OF_EX_control_signals[9]) ? OF_EX_A * OF_EX_B :
                              (OF_EX_control_signals[8]) ? OF_EX_A / OF_EX_B :
                              (OF_EX_control_signals[7]) ? OF_EX_A % OF_EX_B :
                              (OF_EX_control_signals[6]) ? OF_EX_A << OF_EX_B :
                              (OF_EX_control_signals[5]) ? OF_EX_A >> OF_EX_B :
                              (OF_EX_control_signals[4]) ? OF_EX_A >>> OF_EX_B :
                              (OF_EX_control_signals[3]) ? OF_EX_A | OF_EX_B :
                              (OF_EX_control_signals[2]) ? OF_EX_A & OF_EX_B :
                              (OF_EX_control_signals[1]) ? ~OF_EX_B :
                              (OF_EX_control_signals[0]) ? OF_EX_B : 32'b0;
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
                data_memory[EX_MA_aluResult] <= EX_MA_op2;
            else
                data_memory[EX_MA_aluResult] <= data_memory[EX_MA_aluResult];
        end

    always@(posedge clk1)       // RW stage
        begin
            if(MA_RW_control_signals[15])
                begin
                    if(MA_RW_control_signals[13])
                        reg_file[15] <= ({MA_RW_control_signals[13], MA_RW_control_signals[20]}==2'b00) ? MA_RW_aluResult :
                                        ({MA_RW_control_signals[13], MA_RW_control_signals[20]}==2'b01) ? MA_RW_ldResult :
                                        ({MA_RW_control_signals[13], MA_RW_control_signals[20]}==2'b10) ? MA_RW_PC + 1 : 32'b0;
                    else
                        reg_file[MA_RW_instruction[25:22]] <= ({MA_RW_control_signals[13], MA_RW_control_signals[20]}==2'b00) ? MA_RW_aluResult :
                                                              ({MA_RW_control_signals[13], MA_RW_control_signals[20]}==2'b01) ? MA_RW_ldResult :
                                                              ({MA_RW_control_signals[13], MA_RW_control_signals[20]}==2'b10) ? MA_RW_PC + 1 : 32'b0;
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