`ifndef __EXCUTE_SV
`define __EXCUTE_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/execute/alu.sv"
`else
`endif

module execute
    import common::*;
    import pipes::*;(
    input logic clk,reset,
    input decode_data_t dataD,
    output excute_data_t dataE,
    input logic stall_m,
    output logic branch,
    output u64 jump,
    input logic flushde
);
    word_t result;

    alu alu(
        .clk,
        .a(dataD.srca),
        .b(dataD.srcb),
        .alufunc(dataD.ctl.alufunc),
        .result,
        .choose(dataD.ctl.op==ALUW||dataD.ctl.op==ALUIW),
        .is_csr(dataD.ctl.op==CSR||dataD.ctl.op==CSRI)
    );

    always_comb begin
        branch = 0;
        unique case (dataD.ctl.op)
            JAL,BEQ,BLT,BLTU,BNE,BGE,BGEU,JALR:
                branch=dataD.valid; 
            default: begin end
        endcase
    end
    
    u32 r_ins;//raw_instr
    assign r_ins = dataD.raw_instr;
    always_comb begin
        jump=dataD.pc;
        unique case (dataD.ctl.op)
            JAL: 
                jump = dataD.pc + {{43{r_ins[31]}}, {r_ins[31]}, {r_ins[19:12]} ,{ r_ins[20]} , {r_ins[30:21]},{1'b0}};
            JALR:
                jump = dataD.rd1 + {{52{r_ins[31]}}, r_ins[31:20]};
            BEQ,BLT,BLTU: begin
                if(result==1)
                    jump = dataD.pc + {{51{r_ins[31]}}, {r_ins[31]}, {r_ins[7]}, {r_ins[30:25]}, {r_ins[11:8]},{1'b0}};
                else
                    jump = dataD.pc + 4;
            end
            BNE,BGE,BGEU:begin
                if(result==0)
                    jump = dataD.pc + {{51{r_ins[31]}}, {r_ins[31]}, {r_ins[7]}, {r_ins[30:25]}, {r_ins[11:8]}, {1'b0}};
                else
                    jump = dataD.pc + 4;
            end
            default: begin
                
            end
        endcase
        
    end

    always_ff @(posedge clk) begin
        if (reset || flushde) begin
            dataE.valid <= 0;
        end 
        else if (stall_m) dataE<=dataE;
        else begin
            dataE.pc <= dataD.pc;
            dataE.valid <= dataD.valid;
            dataE.raw_instr <= dataD.raw_instr;
            dataE.ctl <= dataD.ctl;
            dataE.dst <= dataD.dst;
            dataE.rd2 <= dataD.rd2;
            dataE.result <= result;
            dataE.csr_dst <= dataD.csr_dst;
            dataE.csr <= dataD.csr;
            dataE.error <= dataD.error;
        end
    end

endmodule
`endif