`ifndef __CSRREG_SV
`define __CSRREG_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr.sv"
`else

`endif
module csrreg
    import common::*;
    import pipes::*;
    import csr_pkg::*;(
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
        mie: 64'h80000000,
        mip: 64'h80000000,
        mtvec: 64'h80000000,
        mstatus: 64'h80000000,
        mscratch: 64'h80000000,
        mepc: 64'h80000000,
        mcause: 64'b10,
        mcycle: 64'h80000000,
        mtval: 64'h80000000,
        satp: 64'h80000000
    };

	always_ff @(posedge clk) begin
		if (reset) begin
			regs <= '0;
			regs.mcause[1] <= 1'b1;
			regs.mepc[31] <= 1'b1;
		end else begin
			regs <= regs_next;
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


	logic handle_csr_op;
	assign handle_csr_op = ((dataM.ctl.op == CSR || dataM.ctl.op == CSRI) && dataM.valid);


    always_comb begin
        flushde = 0;
        flushall = 0;
        if(~stall_m && handle_csr_op)begin
            flushde = 1;
            flushall=1;
        end      
    end
	
	word_t csr_result;
	always_comb begin
		csr_result=0;
		if(~stall_m && handle_csr_op)begin
			unique case(dataM.ctl.alufunc) 
						ALU_CSRW: csr_result=dataM.csr;
						ALU_CSRS: csr_result=dataM.result|dataM.csr;
						ALU_CSRC: csr_result=dataM.result&(~dataM.csr);
						default: begin end
					endcase
		end
	end
	

	// write
    always_comb begin
		regs_next=regs;
		regs_next.mcycle =regs.mcycle+1;
		if(~stall_m && handle_csr_op)begin
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
		end
		
	end

	always_comb begin
		if (~stall_m&& handle_csr_op )
			csrpc=dataM.pc+4;
		else
			csrpc='0;
	end
	
	
endmodule

`endif