`ifndef MMU_SV
`define MMU_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr_pkg.sv"
`endif

module mmu 
    import common::*;
    import pipes::*;
    import csr_pkg::*;(
    input logic clk, reset, en, 
    input u64 va,           // 虚拟地址               
    output u64 pa,          // 翻译后的物理地址
    output logic valid,     // 地址翻译是否有效
    output u64 mem_addr,    // 内存访问地址
    output logic mem_req,   // 内存请求信号
    input  u64 pte,         // 内存返回数据
    input  logic pte_valid, // 内存数据有效信号
    output logic done,      // 地址翻译完成信号
    input satp_t satp,
    input u2  mmode 
);

    enum logic [1:0] {
        IDLE,
        READ,
        DONE
    } state, next_state;
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    reg [43:0] ppn, next_ppn;
    u2 level, next_level;
    u64 next_pa;

    always_ff @(posedge clk) 
    if (reset) begin
        level <= 0;
        ppn <= 0;
        pa <= 0;
    end else begin
        level <= next_level;
        ppn <= next_ppn;
        pa <= next_pa;
    end
    
    always_comb begin
        next_state = state;
        next_level = level;
        next_ppn = ppn;
        next_pa = pa;
        case (state)
        IDLE:
            if (!en || satp[63:60] == 0 || mmode == 'b11) begin
                next_pa = va;
                next_state = IDLE;
            end else if (satp.mode == 8) begin
                next_ppn = satp.ppn;
                next_level = 2;
                next_state = READ;
            end

        READ:
            if (pte_valid) begin
                if (pte[0] == 0) begin // Invalid PTE
                    next_state = DONE;
                end else if (pte[3:1] != 'b000) begin // Leaf PTE
                    next_pa = {8'b0, pte[53:10], va[11:0]};
                    next_state = DONE;
                end else begin
                    next_ppn = pte[53:10];
                    next_state = (level == 0) ? DONE : READ;
                    next_level = level - 1;
                end
            end

        DONE:
            next_state = en ? DONE : IDLE;
        default:
            begin end
        endcase
    end

    assign mem_req = state == READ;
    always_comb case (level)
        2: mem_addr = {8'b0, ppn, va[38:30], 3'b000};
        1: mem_addr = {8'b0, ppn, va[29:21], 3'b000};
        0: mem_addr = {8'b0, ppn, va[20:12], 3'b000};
    endcase
    assign done = !en || satp[63:60] == 0 || mmode == 'b11 || state == DONE;            
    assign valid = 1;
endmodule


`endif