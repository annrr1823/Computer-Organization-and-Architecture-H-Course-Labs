
`ifndef __ALU_SV
`define __ALU_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/execute/mul.sv"
`include "pipeline/execute/div.sv"
`include "pipeline/execute/divu.sv"
`else

`endif

module alu
	import common::*;
	import pipes::*;(
	input u1 clk,
	input u64 a, b,
	input alufunc_t alufunc,
	output u64 result,
	input logic choose

);
	logic[63:0] c;

	u64 mulresult,divresult,remresult,divuresult,remuresult;

	always_comb begin
		c = '0;
			unique case(alufunc)
				ALU_ADD: c = a + b;
				ALU_XOR: c = a ^ b;
				ALU_OR : c = a | b; 
				ALU_AND: c = a & b;
				ALU_SUB: c = a - b;
				ALU_MUL: c = mulresult;
				ALU_DIV: c = (b == 0 ? -1 : divresult);
				ALU_REM: c = (b == 0 ? a : remresult); 
				ALU_DIVU:c = (b == 0 ? -1 : divuresult);
				ALU_REMU:c = (b == 0 ? a : remuresult);
				
				ALU_LUI: c = b;
				ALU_EQUAL: c ={63'b0, (a==b)};
				ALU_SLT: c= {63'b0,( $signed(a) < $signed(b) )};
				ALU_SLTU: c={63'b0,( a < b )};
				ALU_SLL: c = a<<b[5:0];
				ALU_SRL: c = a>>b[5:0];
				ALU_SRA: c = $signed(a)>>>b[5:0];
				default: begin
				end
			endcase
		
		if (choose) begin
			unique case (alufunc)
				ALU_SLL: c = a << b[4:0];
				ALU_SRL: c[31:0] = a[31:0] >> b[4:0];
				ALU_SRA: c[31:0] = $signed(a[31:0]) >>> b[4:0];
				default: begin end
			endcase
			result={{32{c[31]}},c[31:0]};
		end
		else begin
			result=c[63:0];
		end
	end

	mul mul(
		.clk,.a,.b,
		.result(mulresult),
		.valid(alufunc==ALU_MUL)
	);
	div div(
		.clk,.a,.b,
		.result(divresult),.rem(remresult),
		.valid((alufunc==ALU_DIV||alufunc==ALU_REM)&&(b!=0))
	);
	divu divu(
		.clk,.a,.b,
		.result(divuresult),.rem(remuresult),
		.valid((alufunc==ALU_DIVU||alufunc==ALU_REMU)&&(b!=0))
	);

	

endmodule

`endif
