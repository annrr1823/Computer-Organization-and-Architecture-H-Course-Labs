`ifndef __DIV_SV
`define __DIV_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/execute/divu.sv"
`else

`endif

module div
    import common::*;
    import pipes::*;(
    input logic clk,
    input u64 a, b,
    output u64 result,
    output u64 rem,
    input valid
);
    u64 uq,ur;
    divu divu(
        .clk,
        .a(a[63]?-a:a),.b(b[63]?-b:b),
        .result,.rem,
        .valid
    );

    assign result = (a[63]^b[63])?-uq:uq;
    assign rem = a[63] ? -ur:ur;

endmodule

`endif