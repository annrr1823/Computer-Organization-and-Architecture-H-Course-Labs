`ifndef _FETCH_SV
`define _FETCH_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif
module fetch
    import common::*;
    import pipes::*;(
    input logic clk,reset,
    output fetch_data_t dataF,
    output ibus_req_t ireq,
    input ibus_resp_t iresp,
    input logic stall_m,
    input logic branch,
    input u64 jump
);
    u64 pc,pc_next;
    u1 pc_stop;
    logic move,bubble;
    assign pc_stop= (~iresp.data_ok)|stall_m;
    assign ireq.addr=pc;
    assign ireq.valid=~move;
    assign bubble=~iresp.data_ok;
    always_comb begin
        pc_next=0;
        if (reset) pc_next=64'h80000000;
        else if (branch) pc_next=jump;
        else if (pc_stop) pc_next=pc;
        else pc_next=pc+4;
    end

    always_ff @(posedge clk) begin
        move<=(pc!=pc_next);
        if (reset) begin
            pc <= 64'h80000000;
        end else begin
            pc <= pc_next;
        end
    end


    always_ff @(posedge clk) begin
        
        if (reset) begin
            dataF.valid <= 0;
        end
        else if (stall_m) begin       // 内存阶段暂停时保持 dataF 不变
            dataF <= dataF;
        end
        else if (bubble) dataF.valid<=0;
        else begin 
            dataF.pc <= pc;
            dataF.valid <= ~branch;
            dataF.raw_instr <= iresp.data;
        end
    end
endmodule
`endif