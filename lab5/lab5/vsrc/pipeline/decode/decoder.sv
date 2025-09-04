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
    output control_t ctl
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
                    F3_ADD: ctl.alufunc=ADD;
                    F3_XOR: ctl.alufunc=XOR;
                    F3_OR: ctl.alufunc=OR;
                    F3_AND: ctl.alufunc=AND;
                    F3_SR: begin
                        if (raw_instr[30]) begin
                            ctl.alufunc=SRA;
                        end
                        else begin
                            ctl.alufunc=SRL;
                        end
                    end
                    F3_SLT: ctl.alufunc=SLT;
                    F3_SLTU: ctl.alufunc=SLTU;
                    F3_SLL: ctl.alufunc=SLL;
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
                            ctl.alufunc=ADD;
                        end 
                        else if (ff7==F7_FIRST_SUB) begin
                            ctl.alufunc=SUB;
                        end
                        else if (ff7==F7_FIRST_MUL) begin
                            ctl.alufunc=MULT;
                        end
                    end
                    F3_XOR: begin
                        if (ff7==F7_FIRST_MUL) ctl.alufunc=DIV;
                        else ctl.alufunc=XOR;
                    end
                    F3_OR: begin
                        if (ff7==F7_FIRST_MUL) ctl.alufunc=REM;
                        else ctl.alufunc=OR;
                    end
                    F3_AND: begin
                        if (ff7==F7_FIRST_MUL) ctl.alufunc=REMU;
                        else ctl.alufunc=AND;
                    end
                    F3_SR: begin
                        if(ff7==F7_FIRST_ADD)begin
                            ctl.alufunc=SRL;
                        end
                        else if (ff7==F7_FIRST_SUB) begin
                            ctl.alufunc=SRA;
                        end
                        else if (ff7==F7_FIRST_MUL) begin
                            ctl.alufunc=DIVU;
                        end
                    end
                    F3_SLT: ctl.alufunc=SLT;
                    F3_SLTU: ctl.alufunc=SLTU;
                    F3_SLL: ctl.alufunc=SLL;
                    default :begin
                        
                    end
                endcase 
            end
            F7_ALUIW:begin
                ctl.op=ALUIW;
                ctl.regwrite=1'b1;
                unique case(f3)
                    F3_ADD: ctl.alufunc=ADD;
                    F3_AND: ctl.alufunc=AND;
                    F3_OR:  ctl.alufunc=OR;
                    F3_XOR: ctl.alufunc=XOR;
                    F3_SLT: ctl.alufunc=SLT;
                    F3_SLTU: ctl.alufunc=SLTU;
                    F3_SLL: ctl.alufunc=SLL;
                    F3_SR: begin
                        if (raw_instr[30]) begin
                            ctl.alufunc=SRA;
                        end
                        else begin
                            ctl.alufunc=SRL;
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
                            ctl.alufunc=ADD;
                        end 
                        else if (ff7==F7_FIRST_SUB) begin
                            ctl.alufunc=SUB;
                        end
                        else if (ff7==F7_FIRST_MUL) begin
                            ctl.alufunc=MULT;
                        end
                    end
                    F3_AND: begin
                        if (ff7==F7_FIRST_MUL) ctl.alufunc=REMU;
                        else ctl.alufunc=AND;
                    end
                    F3_OR: begin
                        if (ff7==F7_FIRST_MUL) ctl.alufunc=REM;
                        else ctl.alufunc=OR;
                    end
                    F3_XOR: begin
                        if (ff7==F7_FIRST_MUL) ctl.alufunc=DIV;
                        else ctl.alufunc=XOR;
                    end
                    F3_SR: begin
                        if (ff7==F7_FIRST_MUL) begin
                            ctl.alufunc=DIVU;
                        end
                        else if (ff7==F7_FIRST_SUB) begin
                            ctl.alufunc=SRA;
                        end
                        else if(ff7==F7_FIRST_ADD)begin
                            ctl.alufunc=SRL;
                        end
                    end
                    F3_SLT: ctl.alufunc=SLT;
                    F3_SLTU: ctl.alufunc=SLTU;
                    F3_SLL: ctl.alufunc=SLL;
                    default :begin
                        
                    end
                endcase 
            end
            F7_LUI:begin
                ctl.op=LUI;
                ctl.regwrite=1'b1;
                ctl.alufunc=CPYB;
            end
            
            F7_BRANCH: begin
                ctl.regwrite=1'b0;
                ctl.op = f3[0] ? BNZ : BZ;
                unique case(f3)
                    F3_BEQ: begin
                        //ctl.op=BEQ;
                        ctl.alufunc=EQL;
                    end
                    F3_BNE: begin
                        //ctl.op=BNE;
                        ctl.alufunc=EQL;
                    end
                    F3_BLT: begin
                        //ctl.op=BLT;
                        ctl.alufunc=SLT;
                    end
                    F3_BGE: begin
                        //ctl.op=BGE;
                        ctl.alufunc=SLT;
                    end
                    F3_BLTU: begin
                        //ctl.op=BLTU;
                        ctl.alufunc=SLTU;
                    end
                    F3_BGEU: begin
                        //ctl.op=BGEU;
                        ctl.alufunc=SLTU;
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
                        ctl.alufunc = ADD;
                    end
                    F3_LB: begin
                        ctl.op = LB;
                        ctl.regwrite = 1;
                        ctl.alufunc = ADD;
                    end
                    F3_LBU: begin
                        ctl.op = LBU;
                        ctl.regwrite = 1;
                        ctl.alufunc = ADD;
                    end
                    F3_LH: begin
                        ctl.op = LH;
                        ctl.regwrite = 1;
                        ctl.alufunc = ADD;
                    end
                    F3_LHU: begin
                        ctl.op = LHU;
                        ctl.regwrite = 1;
                        ctl.alufunc = ADD;
                    end
                    F3_LW: begin
                        ctl.op = LW;
                        ctl.regwrite = 1;
                        ctl.alufunc = ADD;
                    end
                    F3_LWU: begin
                        ctl.op = LWU;
                        ctl.regwrite = 1;
                        ctl.alufunc = ADD;
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
                        ctl.alufunc = ADD;
                    end
                    F3_SB: begin
                        ctl.op = SB;
                        ctl.regwrite = 0;
                        ctl.alufunc = ADD;
                    end
                    F3_SH: begin
                        ctl.op = SH;
                        ctl.regwrite = 0;
                        ctl.alufunc = ADD;
                    end
                    F3_SW: begin
                        ctl.op = SW;
                        ctl.regwrite = 0;
                        ctl.alufunc = ADD;
                    end
                    default :begin  
                    end
                endcase
            end
            F7_AUIPC: begin
                ctl.op=AUIPC;
                ctl.regwrite=1'b1;
                ctl.alufunc=ADD;
            end
            F7_JAL: begin
                ctl.op=JAL;
                ctl.regwrite=1'b1;
                ctl.alufunc=ADD;
            end
            F7_JALR:begin
                ctl.op=JALR;
                ctl.regwrite=1'b1;
                ctl.alufunc=ADD;
            end
            F7_CSR:begin
                ctl.regwrite=1'b1;
                unique case (f3)
                    F3_CSRRW:begin
                        ctl.op=CSR;
                        ctl.alufunc=ALU_CSRW;
                    end
                    F3_CSRRS:begin
                        ctl.op=CSR;
                        ctl.alufunc=ALU_CSRS;
                    end
                    F3_CSRRC:begin
                        ctl.op=CSR;
                        ctl.alufunc=ALU_CSRC;
                    end
                    F3_CSRRWI:begin
                        ctl.op=CSRI;
                        ctl.alufunc=ALU_CSRW;
                    end
                    F3_CSRRSI:begin
                        ctl.op=CSRI;
                        ctl.alufunc=ALU_CSRS;
                    end
                    F3_CSRRCI:begin
                        ctl.op=CSRI;
                        ctl.alufunc=ALU_CSRC;
                    end
                    F3_MRET:begin
                        ctl.regwrite=1'b0;
                        unique case(ff7)
                            F7_FIRST_ECALL:begin
                                ctl.op = ECALL;
                                ctl.alufunc = ALU_ECALL;
                            end
                            F7_FIRST_MRET:begin
                                ctl.op = MRET;
                                ctl.alufunc = ALU_MRET;
                            end
                            // F7_FIRST_SFENCE:begin
                            //     ctl.op = SFENCE;
                            //     ctl.alufunc = NOTALU;
                            // end
                            default:begin end
                        endcase
                    end
                    default :begin
                        
                    end
                endcase
            end
            default : begin
                
            end
        endcase
    end
endmodule
`endif