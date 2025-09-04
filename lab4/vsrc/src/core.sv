`ifndef __CORE_SV
`define __CORE_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr.sv"
`include "pipeline/regfile/regfile.sv"
`include "pipeline/fetch/fetch.sv"
`include "pipeline/decode/decode.sv"
`include "pipeline/execute/execute.sv"
`include "pipeline/memory/memory.sv"
`include "pipeline/csr/csrreg.sv"
`else

`endif

module core 
	import common::*;
	import pipes::*;
	import csr_pkg::*;(
	input logic clk, reset,
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
	output dbus_req_t  dreq,
	input  dbus_resp_t dresp,
	input logic trint, swint, exint
);
	fetch_data_t dataF;
	decode_data_t dataD;
	excute_data_t dataE;
	memory_data_t dataM;

	creg_addr_t ra1,ra2;  // Read address for reg
	word_t rd1,rd2;       // Read data from reg

	logic stall_m;  //stall logic
	forward_t forward_m,forward_w;//forward dst and data

	u64 jump;
	logic branch;

	u12 csrra;
	word_t csrrd;
	u64 csrpc;

	logic flushde,flushall;

	fetch fetch(
		.clk,.reset,
		.dataF,
		.ireq,.iresp,
		.stall_m,
		.jump,.branch,
		.csrpc,
		.flushall,
		.flushde
	);

	decode decode (
		.clk,.reset,
		.dataF,.dataD,
		.rd1,.rd2,.ra1,.ra2,
		.stall_m,
		.forward_m,.forward_w,
		.branch,
		.csrra,.csrrd,
		.flushde
	);
	
	execute execute(
		.clk,.reset,
		.dataD,.dataE,
		.stall_m,
		.jump,.branch,
		.flushde
	);

	memory memory(
		.clk,.reset,
		.dataE,.dataM,
		.stall_m,
		.dreq,.dresp,
		.forward_m,
		.flushde,.flushall
	);

	regfile regfile(
		.clk, .reset,
		.wen(dataM.ctl.regwrite && dataM.valid),
		.wdest(dataM.dst),
		.wdata(dataM.result),
		.ra1,.ra2,.rd1,.rd2
	);

	csrreg csrreg(
		.clk,.reset,
		.csrpc,
		.csrra,.csrrd,
		.dataM,
		.trint,.swint,.exint,
		.stall_m,
		.flushde,.flushall
	);

	assign forward_w.dst=(dataM.ctl.regwrite & dataM.valid)?dataM.dst:0;
	assign forward_w.data=dataM.result;

	logic skip;
	assign skip=(   dataM.ctl.op==LD||
					dataM.ctl.op==SD||
					dataM.ctl.op==LB||
					dataM.ctl.op==LH||
					dataM.ctl.op==LW||
					dataM.ctl.op==LBU||
					dataM.ctl.op==LHU||
					dataM.ctl.op==LWU||
					dataM.ctl.op==SB||
					dataM.ctl.op==SH||
					dataM.ctl.op==SW   ) && (dataM.addr[31]==0);
	
`ifdef VERILATOR
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (csrreg.regs_next.mhartid[7:0]),
		.index              (0),
		.valid              (~reset && dataM.valid),
		.pc                 (dataM.pc),
		.instr              (dataM.raw_instr),
		.skip    			(skip),
		.isRVC              (0),
		.scFailed           (0),
		.wen                (dataM.ctl.regwrite),
		.wdest              ({3'b0,dataM.dst}),
		.wdata              (dataM.result)
	);
	      
	DifftestArchIntRegState DifftestArchIntRegState (
		.clock              (clk),
		.coreid             (csrreg.regs_next.mhartid[7:0]),
		.gpr_0              (regfile.regs_nxt[0]),
		.gpr_1              (regfile.regs_nxt[1]),
		.gpr_2              (regfile.regs_nxt[2]),
		.gpr_3              (regfile.regs_nxt[3]),
		.gpr_4              (regfile.regs_nxt[4]),
		.gpr_5              (regfile.regs_nxt[5]),
		.gpr_6              (regfile.regs_nxt[6]),
		.gpr_7              (regfile.regs_nxt[7]),
		.gpr_8              (regfile.regs_nxt[8]),
		.gpr_9              (regfile.regs_nxt[9]),
		.gpr_10             (regfile.regs_nxt[10]),
		.gpr_11             (regfile.regs_nxt[11]),
		.gpr_12             (regfile.regs_nxt[12]),
		.gpr_13             (regfile.regs_nxt[13]),
		.gpr_14             (regfile.regs_nxt[14]),
		.gpr_15             (regfile.regs_nxt[15]),
		.gpr_16             (regfile.regs_nxt[16]),
		.gpr_17             (regfile.regs_nxt[17]),
		.gpr_18             (regfile.regs_nxt[18]),
		.gpr_19             (regfile.regs_nxt[19]),
		.gpr_20             (regfile.regs_nxt[20]),
		.gpr_21             (regfile.regs_nxt[21]),
		.gpr_22             (regfile.regs_nxt[22]),
		.gpr_23             (regfile.regs_nxt[23]),
		.gpr_24             (regfile.regs_nxt[24]),
		.gpr_25             (regfile.regs_nxt[25]),
		.gpr_26             (regfile.regs_nxt[26]),
		.gpr_27             (regfile.regs_nxt[27]),
		.gpr_28             (regfile.regs_nxt[28]),
		.gpr_29             (regfile.regs_nxt[29]),
		.gpr_30             (regfile.regs_nxt[30]),
		.gpr_31             (regfile.regs_nxt[31])
	);
	      
	DifftestTrapEvent DifftestTrapEvent(
		.clock              (clk),
		.coreid             (csrreg.regs_next.mhartid[7:0]),
		.valid              (0),
		.code               (0),
		.pc                 (0),
		.cycleCnt           (0),
		.instrCnt           (0)
	);
	
	//mstatus mtvec mip mie mscratch mcause mtval mepc mcycle satp
	DifftestCSRState DifftestCSRState(
		.clock              (clk),
		.coreid             (csrreg.regs_next.mhartid[7:0]),
		.priviledgeMode     (3),//Machine mode!
		.mstatus            (csrreg.regs_next.mstatus),
		.sstatus            (csrreg.regs_next.mstatus & 64'h800000030001e000),
		.mepc               (csrreg.regs_next.mepc),
		.sepc               (0),
		.mtval              (csrreg.regs_next.mtval),
		.stval              (0),
		.mtvec              (csrreg.regs_next.mtvec),
		.stvec              (0),
		.mcause             (csrreg.regs_next.mcause),
		.scause             (0),
		.satp               (csrreg.regs_next.satp),
		.mip                (csrreg.regs_next.mip),
		.mie                (csrreg.regs_next.mie),
		.mscratch           (csrreg.regs_next.mscratch),
		.sscratch           (0),
		.mideleg            (0),
		.medeleg            (0)
	);

	
`endif
endmodule
`endif