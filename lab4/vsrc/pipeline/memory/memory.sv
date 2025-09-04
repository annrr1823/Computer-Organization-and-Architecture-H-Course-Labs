`ifndef __MEMORY_SV
`define __MEMORY_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/memory/read_data.sv"
`include "pipeline/memory/write_data.sv"
`else
`endif

module memory 
    import common::*;
    import pipes::*;(
    input logic clk,reset,
    input excute_data_t dataE,
    output memory_data_t dataM,
    output dbus_req_t  dreq,
	input  dbus_resp_t dresp,
    output logic stall_m,
    output forward_t forward_m,
    input logic flushde,flushall
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
                dreq.valid=dataE.valid&&(dataE.error==0);
                dreq.addr=dataE.result;
                dreq.size=msize;
                rslt=read_rslt;      
            end
            SB, SH, SW, SD: begin
                dreq.valid=dataE.valid&&(dataE.error==0);
                dreq.addr=dataE.result;
                dreq.size=msize;
                dreq.strobe=strobe;
                dreq.data=write_rslt;     
            end
            default: begin
                
            end
        endcase
    end

    error_t error_next;
    logic loaderror,storeerror;
    assign error_next = 0;

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

    logic bubble;

    always_comb begin
    unique case(dataE.ctl.op)
        LB, LH, LW, LBU, LHU, LWU, LD,
        SB, SH, SW, SD:
            bubble=~dresp.data_ok; 
        default: 
            bubble = 0;
        endcase
    end

    assign stall_m=bubble&(dataE.valid&&(dataE.error==0));
    //only needs to be paused when a valid instr is processed
    //and the memory op is not completed
    assign forward_m.dst=(dataE.ctl.regwrite & (dataE.valid && (dataE.error==0)))?dataE.dst:0;
    assign forward_m.data=rslt;

    always_ff @(posedge clk) begin
        if (reset | flushall) begin
            dataM.valid <= 0;
        end 
        else begin
            if (flushde) dataM<=dataM;
            else if (bubble & (dataE.valid|(dataE.error==0))) dataM.valid<=0;
            else begin
                dataM.pc <= dataE.pc;
                dataM.valid <= dataE.valid;
                dataM.raw_instr <= dataE.raw_instr;
                dataM.result <= rslt;
                dataM.ctl <= dataE.ctl;
                dataM.dst <= dataE.dst; 
                dataM.addr <= dataE.result;
                dataM.csr_dst <= dataE.csr_dst;
                dataM.csr <= dataE.csr;
                dataM.error <= error_next;
            end
        end
    end


endmodule
`endif