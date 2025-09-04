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
    output logic bubble_i,
    input logic bubble1,bubble2
);
    always_comb begin      
        outputa=inputa;
        outputb=inputb;
        bubble_i=0;
        unique case(op)
            ALU,ALUW:begin
                bubble_i=bubble1|bubble2;
            end
            ALUI, ALUIW:begin
                outputb={{52{raw_instr[31]}},raw_instr[31:20]};
                bubble_i=bubble1;
            end
            LB, LH, LW, LBU, LHU, LWU, LD: begin
                bubble_i=bubble1;
                outputb={{52{raw_instr[31]}},raw_instr[31:20]};
            end
            SB, SH, SW, SD: begin
                bubble_i=bubble1;
                outputb={{52{raw_instr[31]}},raw_instr[31:25],raw_instr[11:7]};
            end
            LUI: begin
                bubble_i=bubble1;
                outputb={{32{raw_instr[31]}},raw_instr[31:12],{12{1'b0}}};
            end
            JAL,JALR: begin
                outputa=pc;
                outputb=64'd4;
            end
            AUIPC: begin
                outputa=pc;
                outputb={{32{raw_instr[31]}},raw_instr[31:12],{12{1'b0}}};
            end
            default:begin
                bubble_i=bubble1|bubble2;
                
            end
        endcase 
    end
endmodule

`endif