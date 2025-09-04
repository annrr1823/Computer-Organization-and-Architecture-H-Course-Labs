`ifndef __DECODER_SV
`define __DECODER_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else
`endif 
module decoder 
    import common::*;
	import pipes::*;(
    input u32 raw_instr,
    output contral_t ctl
);
    logic [6:0] f7;
    assign f7=raw_instr[6:0];
    logic [2:0] f3;
    assign f3=raw_instr[14:12];
    u7 ff7;
    assign ff7=raw_instr[31:25];
    always_comb begin
        ctl.op=UNKNOWN;
        ctl.alufunc=NOTALU;
        ctl.regwrite=1'b1;
        unique case(f7)
            F7_ALUI:begin
                ctl.op=ALUI;
                ctl.regwrite=1'b1;
                unique case(f3)
                    F3_ADD: ctl.alufunc=ALU_ADD;
                    F3_XOR: ctl.alufunc=ALU_XOR;
                    F3_OR: ctl.alufunc=ALU_OR;
                    F3_AND: ctl.alufunc=ALU_AND;
                    F3_SR: begin
                        if (raw_instr[30]) begin
                            ctl.alufunc=ALU_SRA;
                        end
                        else begin
                            ctl.alufunc=ALU_SRL;
                        end
                    end
                    F3_SLT: ctl.alufunc=ALU_SLT;
                    F3_SLTU: ctl.alufunc=ALU_SLTU;
                    F3_SLL: ctl.alufunc=ALU_SLL;
                    default :begin
                        
                    end
                endcase 
            end
            F7_ALU: begin
                ctl.op=ALU;
                ctl.regwrite=1'b1;
                unique case(f3)
                    F3_ADD: begin
                        if (ff7==F7_FIRST_ADD) begin
                            ctl.alufunc=ALU_ADD;
                        end 
                        else if (ff7==F7_FIRST_SUB) begin
                            ctl.alufunc=ALU_SUB;
                        end
                        else if (ff7==F7_FIRST_MUL) begin
                            ctl.alufunc=ALU_MUL;
                        end
                    end
                    F3_XOR: begin
                        if (ff7==F7_FIRST_MUL) ctl.alufunc=ALU_DIV;
                        else ctl.alufunc=ALU_XOR;
                    end
                    F3_OR: begin
                        if (ff7==F7_FIRST_MUL) ctl.alufunc=ALU_REM;
                        else ctl.alufunc=ALU_OR;
                    end
                    F3_AND: begin
                        if (ff7==F7_FIRST_MUL) ctl.alufunc=ALU_REMU;
                        else ctl.alufunc=ALU_AND;
                    end
                    F3_SR: begin
                        if(ff7==F7_FIRST_ADD)begin
                            ctl.alufunc=ALU_SRL;
                        end
                        else if (ff7==F7_FIRST_SUB) begin
                            ctl.alufunc=ALU_SRA;
                        end
                        else if (ff7==F7_FIRST_MUL) begin
                            ctl.alufunc=ALU_DIVU;
                        end
                    end
                    F3_SLT: ctl.alufunc=ALU_SLT;
                    F3_SLTU: ctl.alufunc=ALU_SLTU;
                    F3_SLL: ctl.alufunc=ALU_SLL;
                    default :begin
                        
                    end
                endcase 
            end
            F7_ALUIW:begin
                ctl.op=ALUIW;
                ctl.regwrite=1'b1;
                unique case(f3)
                    F3_ADD: ctl.alufunc=ALU_ADD;
                    F3_AND: ctl.alufunc=ALU_AND;
                    F3_OR:  ctl.alufunc=ALU_OR;
                    F3_XOR: ctl.alufunc=ALU_XOR;
                    F3_SLT: ctl.alufunc=ALU_SLT;
                    F3_SLTU: ctl.alufunc=ALU_SLTU;
                    F3_SLL: ctl.alufunc=ALU_SLL;
                    F3_SR: begin
                        if (raw_instr[30]) begin
                            ctl.alufunc=ALU_SRA;
                        end
                        else begin
                            ctl.alufunc=ALU_SRL;
                        end
                    end
                    default :begin
                        
                    end
                endcase 
            end
            F7_ALUW: begin
                ctl.op=ALUW;
                ctl.regwrite=1'b1;
                unique case(f3)
                    F3_ADD: begin
                        if (ff7==F7_FIRST_ADD) begin
                            ctl.alufunc=ALU_ADD;
                        end 
                        else if (ff7==F7_FIRST_SUB) begin
                            ctl.alufunc=ALU_SUB;
                        end
                        else if (ff7==F7_FIRST_MUL) begin
                            ctl.alufunc=ALU_MUL;
                        end
                    end
                    F3_AND: begin
                        if (ff7==F7_FIRST_MUL) ctl.alufunc=ALU_REMU;
                        else ctl.alufunc=ALU_AND;
                    end
                    F3_OR: begin
                        if (ff7==F7_FIRST_MUL) ctl.alufunc=ALU_REM;
                        else ctl.alufunc=ALU_OR;
                    end
                    F3_XOR: begin
                        if (ff7==F7_FIRST_MUL) ctl.alufunc=ALU_DIV;
                        else ctl.alufunc=ALU_XOR;
                    end
                    F3_SR: begin
                        if (ff7==F7_FIRST_MUL) begin
                            ctl.alufunc=ALU_DIVU;
                        end
                        else if (ff7==F7_FIRST_SUB) begin
                            ctl.alufunc=ALU_SRA;
                        end
                        else if(ff7==F7_FIRST_ADD)begin
                            ctl.alufunc=ALU_SRL;
                        end
                    end
                    F3_SLT: ctl.alufunc=ALU_SLT;
                    F3_SLTU: ctl.alufunc=ALU_SLTU;
                    F3_SLL: ctl.alufunc=ALU_SLL;
                    default :begin
                        
                    end
                endcase 
            end
            F7_LUI:begin
                ctl.op=LUI;
                ctl.regwrite=1'b1;
                ctl.alufunc=ALU_LUI;
            end
            
            F7_BRANCH: begin
                ctl.regwrite=1'b0;
                unique case(f3)
                    F3_BEQ: begin
                        ctl.op=BEQ;
                        ctl.alufunc=ALU_EQUAL;
                    end
                    F3_BNE: begin
                        ctl.op=BNE;
                        ctl.alufunc=ALU_EQUAL;
                    end
                    F3_BLT: begin
                        ctl.op=BLT;
                        ctl.alufunc=ALU_SLT;
                    end
                    F3_BGE: begin
                        ctl.op=BGE;
                        ctl.alufunc=ALU_SLT;
                    end
                    F3_BLTU: begin
                        ctl.op=BLTU;
                        ctl.alufunc=ALU_SLTU;
                    end
                    F3_BGEU: begin
                        ctl.op=BGEU;
                        ctl.alufunc=ALU_SLTU;
                    end
                    default begin
                        
                    end
                endcase 
            end
            
            F7_LD: begin
                unique case(f3)
                    F3_LD: begin
                        ctl.op = LD;
                        ctl.regwrite = 1;
                        ctl.alufunc = ALU_ADD;
                    end
                    F3_LB: begin
                        ctl.op = LB;
                        ctl.regwrite = 1;
                        ctl.alufunc = ALU_ADD;
                    end
                    F3_LBU: begin
                        ctl.op = LBU;
                        ctl.regwrite = 1;
                        ctl.alufunc = ALU_ADD;
                    end
                    F3_LH: begin
                        ctl.op = LH;
                        ctl.regwrite = 1;
                        ctl.alufunc = ALU_ADD;
                    end
                    F3_LHU: begin
                        ctl.op = LHU;
                        ctl.regwrite = 1;
                        ctl.alufunc = ALU_ADD;
                    end
                    F3_LW: begin
                        ctl.op = LW;
                        ctl.regwrite = 1;
                        ctl.alufunc = ALU_ADD;
                    end
                    F3_LWU: begin
                        ctl.op = LWU;
                        ctl.regwrite = 1;
                        ctl.alufunc = ALU_ADD;
                    end
                    default :begin  
                    end
                endcase 
            end
            F7_SD: begin
                unique case(f3)
                    F3_SD: begin
                        ctl.op = SD;
                        ctl.regwrite = 0;
                        ctl.alufunc = ALU_ADD;
                    end
                    F3_SB: begin
                        ctl.op = SB;
                        ctl.regwrite = 0;
                        ctl.alufunc = ALU_ADD;
                    end
                    F3_SH: begin
                        ctl.op = SH;
                        ctl.regwrite = 0;
                        ctl.alufunc = ALU_ADD;
                    end
                    F3_SW: begin
                        ctl.op = SW;
                        ctl.regwrite = 0;
                        ctl.alufunc = ALU_ADD;
                    end
                    default :begin  
                    end
                endcase
            end
            F7_AUIPC: begin
                ctl.op=AUIPC;
                ctl.regwrite=1'b1;
                ctl.alufunc=ALU_ADD;
            end
            F7_JAL: begin
                ctl.op=JAL;
                ctl.regwrite=1'b1;
                ctl.alufunc=ALU_ADD;
            end
            F7_JALR:begin
                ctl.op=JALR;
                ctl.regwrite=1'b1;
                ctl.alufunc=ALU_ADD;
            end
            default : begin
                
            end
        endcase
    end
endmodule
`endif