`ifndef __WRITE_DATA_SV
`define __WRITE_DATA_SV


`ifdef VERILATOR
`include "include/common.sv"
`else

`endif

module write_data
	import common::*;(
	input u64 _wd,
	output u64 wd,
	input u3 addr,
	input msize_t msize,
	output strobe_t strobe
);
	//The following codes are based on:
	//fudan-systa/Arch-2023Spring-Fudan/Wiki/lab1/introduction
	always_comb begin
		strobe = '0;
		wd = '0;
		unique case(msize)
			MSIZE1: begin //SB
				unique case(addr)
					3'b000: begin
						wd[7-:8] = _wd[7:0];
						strobe = 8'b00000001;
					end
					3'b001: begin
						wd[15-:8] = _wd[7:0];
						strobe = 8'b00000010;
					end
					3'b010: begin
						wd[23-:8] = _wd[7:0];
						strobe = 8'b00000100;
					end
					3'b011: begin
						wd[31-:8] = _wd[7:0];
						strobe = 8'b00001000;
					end
					3'b100: begin
						wd[39-:8] = _wd[7:0];
						strobe = 8'b00010000;
					end
					3'b101: begin
						wd[47-:8] = _wd[7:0];
						strobe = 8'b00100000;
					end
					3'b110: begin
						wd[55-:8] = _wd[7:0];
						strobe = 8'b01000000;
					end
					3'b111: begin
						wd[63-:8] = _wd[7:0];
						strobe = 8'b10000000;
					end
					default: begin
						
					end
				endcase
			end
			MSIZE2: begin //SH
				unique case(addr)
					3'b000: begin
						wd[15-:16] = _wd[15:0];
						strobe = 8'b00000011;
					end
					3'b010: begin
						wd[31-:16] = _wd[15:0];
						strobe = 8'b00001100;
					end
					3'b100: begin
						wd[47-:16] = _wd[15:0];
						strobe = 8'b00110000;
					end
					3'b110: begin
						wd[63-:16] = _wd[15:0];
						strobe = 8'b11000000;
					end
					default: begin

					end
				endcase
			end
			MSIZE4: begin //SW
				unique case(addr)
					3'b000: begin
						wd[31-:32] = _wd[31:0];
						strobe = 8'b00001111;
					end
					3'b100: begin
						wd[63-:32] = _wd[31:0];
						strobe = 8'b11110000;
					end
					default: begin

					end
				endcase
				
			end
			MSIZE8: begin //SD
				unique case(addr)
					3'b000: begin
						wd = _wd;
						strobe = 8'b11111111;
					end
					default: begin

					end
				endcase
			end
			default: begin
				
			end
		endcase
	end
	
endmodule



`endif