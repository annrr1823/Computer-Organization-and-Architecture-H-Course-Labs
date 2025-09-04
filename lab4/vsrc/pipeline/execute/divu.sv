`ifndef __DIVU_SV
`define __DIVU_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module divu
	import common::*;
	import pipes::*;(
    input logic clk,
    input u64 a, b,
    output u64 result,
    output u64 rem,
    input valid
);

    int i = 0;
    logic waiting;
    always_ff @( posedge clk ) begin
        if(valid)begin
            if ((i == 0) && (waiting == 0)) begin
                result=0;
                rem=0;
                i=1;
            end
            if (waiting==1) begin
                i=0;
                result=0;
                rem=0;
                waiting=0;
            end
            if (i==65) begin
                i=0;
                waiting=1;
            end 
            
            if (i >= 1 ) begin
                if(i==1)rem = 0;
                rem = (rem << 1) + {63'b0, a[64 - i]};
                result = result<<1;
                if(rem >= b)begin
                    rem -= b;
                    result += 1;
                end
                i++;
            end   
        end
        else begin
            i=0;
            waiting=0;
            result=0;
            rem=0;
        end
    end
    
endmodule

`endif