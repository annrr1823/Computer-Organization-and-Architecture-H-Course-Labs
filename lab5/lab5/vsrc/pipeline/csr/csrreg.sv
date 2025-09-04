`ifndef __CSRREG_SV
`define __CSRREG_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr_pkg.sv"
`else
`endif

module csrreg
    import common::*;
    import csr_pkg::*;
    import pipes::*; (
		input logic clk, reset,
        output u64 csrpc,
        input u12 csrra,
        output word_t csrrd,
        input memory_data_t dataM,
        input logic trint, swint, exint,
        input logic stall_m,
        output logic flushde, flushall
);

	csr_regs_t regs_next;
    csr_regs_t regs = '{
        mhartid: 0,
        mie: 0,
        mip: 0,
        mtvec: 0,
        mstatus: '0,
        mscratch: 0,
        mepc: 64'h80000000,
        mcause: 64'b10,
        mcycle: 0,
        mtval: 0,
        satp: 0
    };
    u2 mode;
    u2 mode_next;
	always_ff @(posedge clk) begin
		if (reset) begin
			regs <= '0;
			regs.mcause[1] <= 1'b1;
			regs.mepc[31] <= 1'b1;
			mode <= 2'd3;
		end else begin
			regs <= regs_next;
			mode <= mode_next;
		end
	end


    // read
    always_comb begin
		csrrd = '0;
		unique case(csrra)
			CSR_MSTATUS: csrrd = regs.mstatus;
			CSR_MTVEC: csrrd = regs.mtvec;
			CSR_MIP: csrrd = regs.mip;
			CSR_MIE: csrrd = regs.mie;
			CSR_MSCRATCH: csrrd = regs.mscratch;
			CSR_MCAUSE: csrrd = regs.mcause;
			CSR_MTVAL: csrrd = regs.mtval;
			CSR_MEPC: csrrd = regs.mepc;
			CSR_MCYCLE: csrrd = regs.mcycle;
			CSR_MHARTID : csrrd = regs.mhartid;
			CSR_SATP: csrrd = regs.satp;
			
			default: begin
				csrrd = '0;
			end
		endcase
	end

	always_comb begin
        flushde = 0;
        flushall = 0;
        if(~stall_m && dataM.valid && 
				(dataM.ctl.op == CSR || dataM.ctl.op == CSRI||
				 dataM.ctl.op == MRET || dataM.ctl.op == ECALL))begin
            flushde = 1;
            flushall=1;
        end      
    end

	word_t csr_result;
	always_comb begin
		csr_result=0;
		if(~stall_m && (dataM.ctl.op == CSR || dataM.ctl.op == CSRI) && dataM.valid)begin
			unique case(dataM.ctl.alufunc) 
						ALU_CSRW: csr_result=dataM.csr;
						ALU_CSRS: csr_result=dataM.result|dataM.csr;
						ALU_CSRC: csr_result=dataM.result&(~dataM.csr);
						default: begin end
					endcase
		end
	end

	always_comb begin
		mode_next = mode;
		if(~stall_m && dataM.ctl.op == ECALL && dataM.valid)
			mode_next = 2'd3;
		else if(~stall_m && dataM.ctl.op == MRET && dataM.valid)
			mode_next = regs_next.mstatus.mpp;	
	end


    always_comb begin
        regs_next = regs;
        regs_next.mcycle = regs.mcycle + 1;
        if (~stall_m && dataM.ctl.op == ECALL && dataM.valid) begin
			regs_next.mepc = dataM.pc;
			if (mode == 2'b0) regs_next.mcause[62:0] = 63'd8;
			else if (mode == 2'd3) regs_next.mcause[62:0] = 63'd11;
			else regs_next.mcause[63:0] = 64'b0;
			regs_next.mstatus.mpie = regs_next.mstatus.mie;
			regs_next.mstatus.mie = '0;
			regs_next.mstatus.mpp = mode;
            
        end else if (~stall_m && (dataM.ctl.op == CSR || dataM.ctl.op == CSRI) && dataM.valid) begin
			unique case(dataM.csr_dst)
				CSR_MIE: regs_next.mie = csr_result;
				CSR_MIP:  regs_next.mip = csr_result & MIP_MASK;
				CSR_MTVEC: regs_next.mtvec = csr_result & MTVEC_MASK;
				CSR_MSTATUS: regs_next.mstatus = csr_result & MSTATUS_MASK;
				CSR_MSCRATCH: regs_next.mscratch = csr_result;
				CSR_MEPC: regs_next.mepc = csr_result;
				CSR_MCAUSE: regs_next.mcause = csr_result;
				CSR_MCYCLE: regs_next.mcycle = csr_result;
				CSR_MTVAL: regs_next.mtval = csr_result;
				CSR_SATP: regs_next.satp = csr_result;
				default: begin end
			endcase
            
        end else if (~stall_m && (dataM.ctl.op == MRET) && dataM.valid) begin
			regs_next.mstatus.mie = regs_next.mstatus.mpie;
			regs_next.mstatus.mpie = 1'b1;
			regs_next.mstatus.mpp = 2'b0;
            
        end
    end

	always_comb begin
		if (~stall_m && dataM.ctl.op == ECALL && dataM.valid)
			csrpc = regs_next.mtvec;
		else if (~stall_m && (dataM.ctl.op == CSR || dataM.ctl.op == CSRI) && dataM.valid)
			csrpc=dataM.pc+4;
		else if (~stall_m && dataM.ctl.op == MRET && dataM.valid)
			csrpc = regs_next.mepc;
		else
			csrpc='0;
	end


endmodule

`endif
