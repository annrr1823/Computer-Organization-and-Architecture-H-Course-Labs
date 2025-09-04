
`ifndef __SV
`define __SV

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
	input logic choose,
	input logic is_csr

);
	logic[63:0] c;

	u64 mulresult,divresult,remresult,divuresult,remuresult;

	always_comb begin
		c = '0;
		if (is_csr) begin
			c = a;
		end
		else begin
			unique case(alufunc)
				ADD: c = a + b;
				XOR: c = a ^ b;
				OR : c = a | b; 
				AND: c = a & b;
				SUB: c = a - b;
				CPYB: c = b;
				MULT: c = mulresult;
				DIV: c = (b == 0 ? -1 : divresult);
				REM: c = (b == 0 ? a : remresult); 
				DIVU:c = (b == 0 ? -1 : divuresult);
				REMU:c = (b == 0 ? a : remuresult);
				EQL: c ={63'b0, (a==b)};
				SLT: c= {63'b0,( $signed(a) < $signed(b) )};
				SLTU: c={63'b0,( a < b )};
				SLL: c = a<<b[5:0];
				SRL: c = a>>b[5:0];
				SRA: c = $signed(a)>>>b[5:0];
				default: begin
				end
			endcase
		end
		if (choose) begin
			unique case (alufunc)
				SLL: c = a << b[4:0];
				SRL: c[31:0] = a[31:0] >> b[4:0];
				SRA: c[31:0] = $signed(a[31:0]) >>> b[4:0];
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
		.valid(alufunc==MULT)
	);
	div div(
		.clk,.a,.b,
		.result(divresult),.rem(remresult),
		.valid((alufunc==DIV||alufunc==REM)&&(b!=0))
	);
	divu divu(
		.clk,.a,.b,
		.result(divuresult),.rem(remuresult),
		.valid((alufunc==DIVU||alufunc==REMU)&&(b!=0))
	);

	

endmodule

`endif
