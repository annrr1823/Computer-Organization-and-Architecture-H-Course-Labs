`ifndef _MEMORY_SV
`define _MEMORY_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr_pkg.sv"
`include "pipeline/memory/read_data.sv"
`include "pipeline/memory/write_data.sv"
`include "pipeline/memory/mmu.sv"
`endif

module memory
    import common::*;
    import pipes::*;
    import csr_pkg::*;(
    input logic clk,reset,
    input excute_data_t dataE,
    output memory_data_t dataM,
    output dbus_req_t  dreq,
	input  dbus_resp_t dresp,
    output logic stall_m,
    input logic flushde,flushall,
    input satp_t satp,
    input u2 mode
);
    logic valid, mem_req, done;
    wire[63:0] addr, mem_addr;
    wire[2:0] funct3 = dataE.raw_instr[14:12];
    logic load,store;
    always_comb begin
        load=0;
        store=0;
        unique case(dataE.ctl.op)
            LB, LH, LW, LBU, LHU, LWU, LD:load=1;    
            SB, SH, SW, SD: store=1;   
            default: begin end
        endcase
    end
    mmu mmmu(
        .clk, .reset,
        .en((load | store) & dataE.valid),
        .va(dataE.result),
        .satp,
        .mmode(mode),
        .pa(addr),
        .valid,
        .mem_addr,
        .mem_req,
        .pte(dresp.data),
        .pte_valid(dresp.data_ok),
        .done
    );
    
    msize_t msize;
    u1 mem_unsigned;
    word_t rslt,write_rslt,read_rslt;//result
    strobe_t strobe;
    always_comb begin
        unique case (dataE.ctl.op)
            LB,SB,LBU: msize=MSIZE1;
            LH,SH,LHU: msize=MSIZE2;
            LW,SW,LWU: msize=MSIZE4;
            LD,SD:     msize=MSIZE8;
            default:   msize=MSIZE8;
        endcase
    end
    always_comb begin  
        unique case (dataE.ctl.op)
            LB,SB,LH,SH,LW,SW,LD,SD :mem_unsigned=0;
            LBU,LHU,LWU:mem_unsigned=1;
            default: mem_unsigned=0;
        endcase
    end

    always_comb begin
        dreq='0;
        rslt=dataE.result;
        unique case(dataE.ctl.op)
            LB, LH, LW, LBU, LHU, LWU, LD: begin
                dreq.valid=done ? dataE.valid : mem_req & dataE.valid;
                dreq.addr=done ? addr : mem_addr;
                dreq.size=done ? msize : MSIZE8;
                rslt=read_rslt;      
            end
            SB, SH, SW, SD: begin
                dreq.valid=done ? dataE.valid : mem_req & dataE.valid;
                dreq.addr=done ? addr : mem_addr;
                dreq.size=done ? msize : MSIZE8;
                dreq.strobe=done ? strobe : 0;
                dreq.data=write_rslt;     
            end
            default: begin
                
            end
        endcase
    end

    read_data read_data(
        ._rd(dresp.data),.rd(read_rslt),
        .addr(dataE.result[2:0]),
        .msize,.mem_unsigned,
        .loaderror
    );
    write_data write_data(
        ._wd(dataE.rd2),.wd(write_rslt),
        .addr(dataE.result[2:0]),
        .msize,.strobe,
        .storeerror
    );

    error_t error_next;
    logic loaderror,storeerror;
    assign error_next = dataE.error != NOERROR ? dataE.error :
                        // misalign ? (load ? LOAD_MISALIGN : STORE_MISALIGN):
                        done & ~valid ? PAGE_FAULT : NOERROR;;

    
    assign stall_m = ~done | (valid & ((load | store) & !dresp.data_ok & dataE.valid));

    always_ff @(posedge clk) 
    if (reset || flushall)
        dataM.valid  <= 0;
    else if(!flushde) begin
        dataM.pc     <= dataE.pc;
        dataM.valid  <= (!stall_m & dataE.valid); // (!(load | store) | dresp.data_ok) & dataE.valid;
        dataM.raw_instr  <= dataE.raw_instr;
        dataM.ctl    <= dataE.ctl;
        dataM.dst    <= dataE.dst;
        dataM.result <= rslt;
        dataM.addr   <= dataE.result;
        dataM.csr_dst <= dataE.csr_dst;
        dataM.csr    <= dataE.csr;
        dataM.error  <= error_next;
    end
endmodule

`endif