`ifndef __MUL_SV
`define __MUL_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module mul
	import common::*;
	import pipes::*;(
    input logic clk,
    input u64 a, b,
	output u64 result,
    input valid
);

    int i=0;
    logic waiting=0;
    always_ff @( posedge clk ) begin
        if (valid) begin
            if ((i == 0) && (waiting == 0)) begin
                result=0;
                i=1;
            end
            if (waiting==1) begin
                i=0;
                waiting=0;
                result=0;
            end
            if (i==65) begin
                i=0;
                waiting=1;
            end 
            
            if (i >= 1 ) begin
                if (b[i]) begin
                    result = result + (a << (i));
                end
                i++;
            end     
        end
        else begin
            i=0;
            waiting=0;
            result=0;
        end
    end
endmodule

`endif