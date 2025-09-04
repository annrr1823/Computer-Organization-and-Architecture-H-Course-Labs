`ifndef __IMMEDIATE_SV
`define __IMMEDIATE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module imm_r
	import common::*;
	import pipes::*;(
    input word_t inputa,inputb,
	input decode_op_t op,
    input alufunc_t alufunc,
    input u32 raw_instr,
    output word_t outputa,outputb,
    input u64 pc,
    input word_t csr
);
    always_comb begin      
        outputa=inputa;
        outputb=inputb;
        unique case(op)
            ALU,ALUW:begin
                outputa=inputa;
                outputb=inputb;
            end
            ALUI, ALUIW:begin
                outputb={{52{raw_instr[31]}},raw_instr[31:20]};
            end
            LB, LH, LW, LBU, LHU, LWU, LD: begin
                outputb={{52{raw_instr[31]}},raw_instr[31:20]};
            end
            SB, SH, SW, SD: begin
                outputb={{52{raw_instr[31]}},raw_instr[31:25],raw_instr[11:7]};
            end
            LUI: begin
                outputb={{32{raw_instr[31]}},raw_instr[31:12],{12{1'b0}}};
            end
            JAL,JALR: begin
                outputa=pc;
                outputb=4;
            end
            AUIPC: begin
                outputa=pc;
                outputb={{32{raw_instr[31]}},raw_instr[31:12],{12{1'b0}}};
            end
            CSR : begin
                outputb=inputa;
                outputa=csr;
            end
            CSRI : begin
                outputb={59'b0, raw_instr[19:15]};
                outputa=csr;
            end
            default:begin
                
            end
        endcase 
    end
endmodule

`endif