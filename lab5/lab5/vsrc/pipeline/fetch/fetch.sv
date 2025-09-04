`ifndef _FETCH_SV
`define _FETCH_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr_pkg.sv"
`include "pipeline/memory/mmu.sv"
`else

`endif
module fetch
    import common::*;
    import pipes::*;
    import csr_pkg::*;(
    input logic clk,reset,
    output fetch_data_t dataF,
    output ibus_req_t ireq,
    input ibus_resp_t iresp,
    input logic stall_m,
    input logic branch,
    input u64 jump,
    input u64 csrpc,
    input logic flushall,
    input  decode_op_t  op,
    input  dbus_resp_t  dresp,
    output dbus_req_t   dreq,
    input satp_t satp,
    input u2 mode
);
    u64 pc,pc_next;
    assign ireq.addr=addr;
    assign ireq.valid=req && done;
    always_comb begin
        pc_next=0;
        if (reset) pc_next=64'h80000000;
        else if (flushall) pc_next=csrpc;
        else if (branch) pc_next=jump;
        else if ((~iresp.data_ok)|stall_m) pc_next=pc;
        else pc_next=pc+4;
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            pc <= 64'h80000000;
        end else begin
            pc <= pc_next;
        end
    end

    logic req, done, valid;
    always_ff @(posedge clk)
        if(req || (op != MRET && op != ECALL)) 
            req <=( pc == pc_next);
        else
            req <= flushall;

    u64 addr;

    mmu fmmu(
        .clk, .reset,
        .en(req),
        .va(pc),
        .satp,
        .mmode(mode),
        .pa(addr),
        .valid,
        .mem_addr(dreq.addr),
        .mem_req(dreq.valid),
        .pte(dresp.data),
        .pte_valid(dresp.data_ok),
        .done
    );

    assign dreq.size = MSIZE8;
    assign dreq.strobe = 0;
    assign dreq.data = 0;

    always_ff @(posedge clk) begin 
        if (reset) begin
            dataF.valid <= 0;
            dataF.raw_instr <= 0;
            dataF.pc <= 0;
            dataF.error <= NOERROR;
        end
        else if (flushall || ~iresp.data_ok) begin
            dataF.valid <= 0;
        end
        else if (stall_m) begin       // 内存阶段暂停时保持 dataF 不变
            dataF <= dataF;
        end
        else begin 
            dataF.pc <= pc;
            dataF.valid <= ~branch;
            dataF.raw_instr <= iresp.data;
            dataF.error <=NOERROR;
        end
    end
endmodule
`endif