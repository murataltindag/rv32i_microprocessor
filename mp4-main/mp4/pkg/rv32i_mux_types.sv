package pcmux;
typedef enum bit [2:0] {
    pc_plus4  = 3'b000
    ,alu_out  = 3'b001
    ,alu_mod2 = 3'b010
    ,br_out   = 3'b011
    ,btb_pc  = 3'b100
    ,ex_pc_plus4 = 3'b101
} pcmux_sel_t;
endpackage

package cmpmux;
typedef enum bit [1:0] {
    rs2_out = 2'b00
    ,imm = 2'b01 //changed from i_imm to imm
    ,f_rs2 = 2'b10
} cmpmux_sel_t;
endpackage

package alumux;
typedef enum bit [1:0] {
    rs1_out = 2'b00
    ,pc_out = 2'b01
    ,zero = 2'b10
    ,f_rs1 = 2'b11
} alumux1_sel_t;

typedef enum bit [1:0] {
    imm    = 2'b00
    ,rs2_out = 2'b01
    ,f_rs2 = 2'b10
} alumux2_sel_t;
endpackage

package wbmux;
typedef enum bit [2:0] {
    alu_out   = 3'b000
    ,br_en    = 3'b001
    ,lw = 3'b010
    ,lb = 3'b011
    ,lbu = 3'b100
    ,lh = 3'b101
    ,lhu = 3'b110
        ,pc_plus4 = 3'b111

} wbmux_sel_t;
endpackage

package ifmux;
typedef enum bit {
    instr_data = 1'b0
    ,no_op = 1'b1 
} ifmux_sel_t;
endpackage
