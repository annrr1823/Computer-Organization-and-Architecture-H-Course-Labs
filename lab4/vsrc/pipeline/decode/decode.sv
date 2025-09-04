`ifndef __DECODE_SV
`define __DECODE_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/decode/decoder.sv"
`include "pipeline/decode/imm_r.sv"
`else
`endif

module decode 
    import common::*;
    import pipes::*;(
    input logic clk,reset,
    input fetch_data_t dataF,
    output decode_data_t dataD,
    input word_t rd1,rd2,
    output creg_addr_t ra1,ra2,
    input logic stall_m,
    input forward_t forward_m,forward_w,
    input logic branch,
    output u12 csrra,
    input word_t csrrd,
    input logic flushde
);
    contral_t ctl;
    
    assign ra2 = dataF.raw_instr[24:20];
    assign ra1 = dataF.raw_instr[19:15];

    word_t temp1, temp2;
    always_comb begin
        temp1 = rd1;    // First  op from reg
        temp2 = rd2;    // Second op from reg
        if (ra1 != 0) begin
            if (ra1 == forward_m.dst)  // Check if Memory is writing to source reg
                temp1 = forward_m.data;
            else if (ra1 == forward_w.dst)   // Check if Writeback is writing to source reg
                temp1 = forward_w.data;
        end
        if (ra2 != 0) begin
            if (ra2 == forward_m.dst)//Memory
                temp2 = forward_m.data;
            else if (ra2 == forward_w.dst)//Writeback
                temp2 = forward_w.data;
        end
    end

    decoder decoder(
        .raw_instr(dataF.raw_instr),
        .ctl
    );

    word_t srca,srcb;
    imm_r imm_r(
        .inputa(temp1),.inputb(temp2),
        .op(ctl.op),
        .alufunc(ctl.alufunc),
        .raw_instr(dataF.raw_instr),
        .outputa(srca),.outputb(srcb),
        .pc(dataF.pc),
        .csr(csrrd)
    );
    assign csrra=dataF.raw_instr[31:20];
    always_ff @(posedge clk) begin
        if (reset|branch|flushde) dataD.valid <= 0;
        else if (stall_m) dataD<=dataD;
        else begin
            dataD.pc <= dataF.pc;
            dataD.valid <= dataF.valid;
            dataD.raw_instr <= dataF.raw_instr;
            dataD.ctl <= ctl;
            dataD.dst <= dataF.raw_instr[11:7];
            dataD.srca <= srca;
            dataD.srcb <= srcb;
            dataD.rd1 <= temp1;
            dataD.rd2 <= temp2;
            dataD.csr_dst <= csrra;
            dataD.csr <= srcb;
            dataD.error <=(dataF.error==NOERROR && (ctl.op==UNKNOWN))?DECODEERRRE:dataF.error;
        end
    end

endmodule
`endif