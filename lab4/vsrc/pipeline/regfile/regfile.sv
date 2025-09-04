
`ifndef __REGFILE_SV
`define __REGFILE_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif
module regfile 
    import common::*;
    import pipes::*;(
    input logic clk, reset,
    input logic wen,
    input creg_addr_t wdest,
    input u64 wdata,
    input creg_addr_t ra1, ra2,
    output u64 rd1, rd2
);


    // Reg arrays - current values and next cycle values
    u64 [31:0] regs, regs_nxt;
    
    assign rd1 = regs[ra1];
    assign rd2 = regs[ra2];
    
    always_ff @(posedge clk) begin
        if (reset) begin
            regs <= '0;
        end else begin
            regs <= regs_nxt;
            regs[0] <= '0;
        end
    end

    for (genvar i = 1; i < 32; i++) begin         //x0 reg not considered
        always_comb begin
            regs_nxt[i] = ((i == wdest) && wen)? wdata: regs[i];
        end
    end
    
endmodule



`endif
