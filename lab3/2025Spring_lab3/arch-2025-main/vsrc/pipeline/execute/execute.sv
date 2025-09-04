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
    output forward_t forward_e 
);
    word_t result;
    logic bubble;

    alu alu(
        .clk,
        .a(dataD.srca),
        .b(dataD.srcb),
        .alufunc(dataD.ctl.alufunc),
        .result,
        .choose(dataD.ctl.op==ALUW||dataD.ctl.op==ALUIW)
    );

    assign branch = ((dataD.ctl.op==BZ)||(dataD.ctl.op==BNZ)||
                     (dataD.ctl.op==JALR)||(dataD.ctl.op==JAL))&& dataD.valid;
    
    u32 r_ins;//raw_instr
    assign r_ins = dataD.raw_instr;
    always_comb begin
        unique case (dataD.ctl.op)
            JAL: 
                jump = dataD.pc + {{43{r_ins[31]}}, r_ins[31], r_ins[19:12] , r_ins[20] , r_ins[30:21], 1'b0};
            JALR:
                jump = dataD.rd1 + {{52{r_ins[31]}}, r_ins[31:20]};
            BZ: begin
                if(result==1)
                    jump = dataD.pc + {{51{r_ins[31]}}, r_ins[31], r_ins[7], r_ins[30:25], r_ins[11:8], 1'b0};
                else
                    jump = dataD.pc + 4;
            end
            BNZ:begin
                if(result==0)
                    jump = dataD.pc + {{51{r_ins[31]}}, r_ins[31], r_ins[7], r_ins[30:25], r_ins[11:8], 1'b0};
                else
                    jump = dataD.pc + 4;
            end
            default: begin
                jump = dataD.pc + 4;
            end
        endcase
        
    end

    assign forward_e.data=result;
    assign forward_e.dst=(dataD.ctl.regwrite&(dataD.valid))?dataD.dst:0;
    assign forward_e.ismem=(dataD.ctl.op==LD|
                            dataD.ctl.op==LB|
                            dataD.ctl.op==LH|
                            dataD.ctl.op==LW|
                            dataD.ctl.op==LBU|
                            dataD.ctl.op==LHU|
                            dataD.ctl.op==LWU);

    always_ff @(posedge clk) begin
        if (reset) begin
            dataE.valid <= 0;
        end 
        else if (stall_m) dataE<=dataE;
        else begin
            dataE.pc <= dataD.pc;
            dataE.valid <= (!bubble) && dataD.valid;
            dataE.raw_instr <= dataD.raw_instr;
            dataE.ctl <= dataD.ctl;
            dataE.dst <= dataD.dst;
            dataE.rd2 <= dataD.rd2;
            dataE.result <= result;
        end
    end

endmodule
`endif