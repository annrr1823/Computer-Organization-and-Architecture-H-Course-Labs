`ifndef __PIPES_SV
`define __PIPES_SV
`ifdef VERILATOR
`include "include/common.sv"
`endif
package pipes;
	import common::*;
/* Define instrucion decoding rules here */

// parameter F7_RI = 7'bxxxxxxx;
parameter F7_ALUI=   7'b0010011;
parameter F7_ALU=    7'b0110011;
parameter F7_ALUW=	 7'b0111011;
parameter F7_ALUIW=	 7'b0011011;
parameter F7_LUI=    7'b0110111;
parameter F7_JAL=    7'b1101111;
parameter F7_BRANCH= 7'b1100011;

parameter F7_LD=     7'b0000011;
parameter F7_SD=     7'b0100011;
parameter F7_AUIPC=  7'b0010111;
parameter F7_JALR=   7'b1100111;

parameter F7_CSR=	 7'b1110011;

parameter F3_ADD=3'b000;
parameter F3_XOR=3'b100;
parameter F3_OR=3'b110;
parameter F3_AND=3'b111;

parameter F3_LD=3'b011;
parameter F3_LB=3'b000;
parameter F3_LH=3'b001;
parameter F3_LW=3'b010;
parameter F3_LBU=3'b100;
parameter F3_LHU=3'b101;
parameter F3_LWU=3'b110;

parameter F3_SD=3'b011;
parameter F3_SB=3'b000;
parameter F3_SH=3'b001;
parameter F3_SW=3'b010;


parameter F3_BEQ=3'b000;
parameter F3_BNE=3'b001;
parameter F3_BLT=3'b100;
parameter F3_DIV=3'b100;
parameter F3_REM=3'b110;
parameter F3_DIVU=3'b101;
parameter F3_REMU=3'b111;
parameter F3_BGE=3'b101;
parameter F3_BLTU=3'b110;
parameter F3_BGEU=3'b111;
parameter F3_SLT=3'b010;
parameter F3_SLTU=3'b011;
parameter F3_SLL=3'b001;
parameter F3_SR=3'b101;

parameter F3_CSRRW=3'b001;
parameter F3_CSRRS=3'b010;
parameter F3_CSRRC=3'b011;
parameter F3_CSRRWI=3'b101;
parameter F3_CSRRSI=3'b110;
parameter F3_CSRRCI=3'b111;
parameter F3_MRET=3'b000;

parameter F7_FIRST_ADD=7'b0000000;
parameter F7_FIRST_SUB=7'b0100000;
parameter F7_FIRST_MUL=7'b0000001;
parameter F7_FIRST_ECALL=7'b0000000;
parameter F7_FIRST_MRET=7'b0011000;
parameter F7_FIRST_SFENCE=7'b0001001;



/* Define pipeline structures here */
typedef enum logic[5:0] {
	UNKNOWN,NOP,ALUI,ALU,ALUW,ALUIW,
	LD,SD,LB,LH,LW,LBU,LHU,LWU,SB,SH,SW,
	LUI,
	BZ,BNZ,BEQ,BNE,BLT,BGE,BLTU,BGEU,
	AUIPC,JALR,JAL,
	CSR,CSRI,
	ECALL,MRET,SFENCE
} decode_op_t;

typedef enum logic [4:0] {
	NOTALU,ADD,XOR,OR,AND,SUB,
	CPYB,EQL,SLT,
	MULT,DIV,REM,DIVU,REMU,
	ALU_LUI,
	ALU_EQUAL,ALU_LESS,ALU_LESSU,
	SLTU,SLL,SRL,SRA,
	ALU_CSRW,ALU_CSRS,ALU_CSRC,
	ALU_ECALL,ALU_MRET
} alufunc_t;

typedef enum logic [2:0] {
	NOERROR, INSTR_MISALIGN, EDECODE, LOAD_MISALIGN, STORE_MISALIGN, PAGE_FAULT
} error_t;


typedef struct packed {
	u1 ismem;
	creg_addr_t dst; // 不写入时置为x0
	word_t data;
} forward_t;
typedef struct packed {
	decode_op_t op;
	alufunc_t alufunc;
	u1 regwrite;
} control_t;
typedef struct packed {
	u64 pc;
	logic valid;
	u32 raw_instr;
	error_t error;
} fetch_data_t;
typedef struct packed {
	u64 pc;
	logic valid;
	u32 raw_instr;
	control_t ctl;
	creg_addr_t dst;
	word_t srca, srcb;	
	word_t rd1,rd2;
	u12 csr_dst;
	word_t csr;
	error_t error;
} decode_data_t;
typedef struct packed {
	u64 pc;
	u1 valid;
	u32 raw_instr;
	control_t ctl;
	creg_addr_t dst;
	word_t rd2;
	word_t result;
	u12 csr_dst;
	word_t csr;
	error_t error;
} excute_data_t;
typedef struct packed {
	u64 pc;
	u1 valid;
	u32 raw_instr;
	control_t ctl;
	creg_addr_t dst;
	word_t result;
	word_t addr;
	u12 csr_dst;
	word_t csr;
	error_t error;
} memory_data_t;
endpackage

`endif
