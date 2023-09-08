package rv32i_types;
// Mux types are in their own packages to prevent identiier collisions
// e.g. pcmux::pc_plus4 and regfilemux::pc_plus4 are seperate identifiers
// for seperate enumerated types
import pcmux::*;
import cmpmux::*;
import alumux::*;
import wbmux::*;

typedef logic [31:0] rv32i_word;
typedef logic [4:0] rv32i_reg;
typedef logic [3:0] rv32i_mem_wmask;

typedef enum bit [6:0] {
    op_lui   = 7'b0110111, //load upper immediate (U type)
    op_auipc = 7'b0010111, //add upper immediate PC (U type)
    op_jal   = 7'b1101111, //jump and link (J type)
    op_jalr  = 7'b1100111, //jump and link register (I type)
    op_br    = 7'b1100011, //branch (B type)
    op_load  = 7'b0000011, //load (I type)
    op_store = 7'b0100011, //store (S type)
    op_imm   = 7'b0010011, //arith ops with register/immediate operands (I type)
    op_reg   = 7'b0110011, //arith ops with register operands (R type)
    op_csr   = 7'b1110011  //NOT NECESSARY - control and status register (I type)
} rv32i_opcode;

typedef enum bit [2:0] {
    beq  = 3'b000,
    bne  = 3'b001,
    blt  = 3'b100,
    bge  = 3'b101,
    bltu = 3'b110,
    bgeu = 3'b111
} branch_funct3_t;

typedef enum bit [2:0] {
    lb  = 3'b000,
    lh  = 3'b001,
    lw  = 3'b010,
    lbu = 3'b100,
    lhu = 3'b101
} load_funct3_t;

typedef enum bit [2:0] {
    sb = 3'b000,
    sh = 3'b001,
    sw = 3'b010
} store_funct3_t;

typedef enum bit [2:0] {
    add  = 3'b000, //check bit30 for sub if op_reg opcode
    sll  = 3'b001,
    slt  = 3'b010, // slti
    sltu = 3'b011, // sltiu
    axor = 3'b100,
    sr   = 3'b101, // srai - check bit30 for logical/arithmetic
    aor  = 3'b110,
    aand = 3'b111
} arith_funct3_t;

typedef enum bit [2:0] {
    alu_add = 3'b000,
    alu_sll = 3'b001,
    alu_sra = 3'b010,
    alu_sub = 3'b011,
    alu_xor = 3'b100,
    alu_srl = 3'b101,
    alu_or  = 3'b110,
    alu_and = 3'b111
} alu_ops;

typedef enum bit [2:0] {
    cmp_eq = 3'b000,
    cmp_ne = 3'b001,
    cmp_lt = 3'b100,
    cmp_ge = 3'b101,
    cmp_ltu = 3'b110,
    cmp_geu = 3'b111
} cmp_ops;

typedef struct packed {
    logic [31:0] inst;
    logic [31:0] trap;

    // Regfile:
    logic [4:0] rs1_addr;
    logic [4:0] rs2_addr;
    logic [31:0] rs1_rdata;
    logic [31:0] rs2_rdata;
    // get loadregfile from cw
    // get rd from cw
    logic [31:0] rd_wdata;

    // PC:
    logic [31:0] pc_rdata;
    logic [31:0] pc_wdata; // modify on branch misprediction

    // Memory:
    logic [31:0] mem_addr;
    logic [3:0] mem_rmask; // set based on instruction/mem_byte_enable
    logic [3:0] mem_wmask; // 
    logic [31:0] mem_rdata;
    logic [31:0] mem_wdata;
} rv32i_rvfi_monitor_t;

typedef struct packed {
    rv32i_opcode opcode;
    alu_ops aluop;
    cmp_ops cmpop;
    alumux::alumux1_sel_t alumux1_sel;
    alumux::alumux2_sel_t alumux2_sel;
    logic [1:0] pcmux_sel;
    logic cmpmux_sel;
    logic load_pc;
    logic load_regfile;
    logic mem_read;
    logic mem_write;
    logic [4:0] rd;
    wbmux::wbmux_sel_t wb_sel;
    logic [2:0] funct3;
    rv32i_rvfi_monitor_t monitor_info;
    logic[1:0] btb_flag;
} rv32i_control_word;

typedef struct packed {
    logic [31:0] pc_out;
    logic [31:0] instr_data;
    logic [23:0] instr_tag;
    logic instr_valid;
    logic [1:0] btb_flag;
} rv32i_if_id_t;

typedef struct packed {
    logic [31:0] pc_out;
    logic [31:0] imm;
    logic [31:0] rs1_out;
    logic [31:0] rs2_out;
    rv32i_control_word cw;
    logic [4:0] rs1;
    logic [4:0] rs2;
} rv32i_id_ex_t;

typedef struct packed {
    logic [31:0] pc_out;
    logic [4:0] rs2;
    logic [31:0] rs2_out;
    logic [31:0] alu_out;
    logic [31:0] br_en;
    rv32i_control_word cw;
} rv32i_ex_mem_t;

typedef struct packed {
    logic [31:0] pc_out;
    logic [31:0] alu_out;
    logic [31:0] br_en;
    rv32i_control_word cw;
    rv32i_word mem_rdata;
} rv32i_mem_wb_t;



endpackage : rv32i_types

