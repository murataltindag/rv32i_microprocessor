module stage_reg 
import rv32i_types::*;
#(
    parameter has_pc_out = 1'b0,        // IF/ID, ID/EX
    parameter has_instr_data = 1'b0,    // IF/ID
    parameter has_imm = 1'b0,           // ID/EX
    parameter has_rs1_out = 1'b0,       // ID/EX
    parameter has_rs2_out = 1'b0,       // ID/EX, EX/MEM
    parameter has_rs1 = 1'b0,       // ID/EX
    parameter has_rs2 = 1'b0,       // ID/EX
    parameter has_alu_out = 1'b0,       // EX/MEM, MEM/WB
    parameter has_br_en = 1'b0,         // EX/MEM, MEM/WB
    parameter has_cw = 1'b0,            // ID/EX, EX/MEM, MEM/WB
    parameter has_mem_rdata = 1'b0,     // MEM/WB
    parameter has_btb_flag = 1'b0   // IF/ID
)
(
    input clk,
    input rst,
    input load,
    input logic [31:0] pc_out_i,
    input logic [31:0] instr_data_i,
    input logic [23:0] instr_tag_i, // TODO: change size if needed
    input logic instr_valid_i,
    input logic [31:0] imm_i, 
    input logic [31:0] rs1_out_i,
    input logic [31:0] rs2_out_i,
    input logic [31:0] alu_out_i,
    input logic [31:0] br_en_i,
    input logic [31:0] mem_rdata_i,
    input rv32i_control_word cw_i,
    input logic [4:0] rs1_i,
    input logic [4:0] rs2_i,
    input logic [1:0] btb_flag_i, // new

    output rv32i_if_id_t if_id,
    output rv32i_id_ex_t id_ex,
    output rv32i_ex_mem_t ex_mem,
    output rv32i_mem_wb_t mem_wb
);


logic [31:0] pc_out_o;
logic [31:0] instr_data_o;
logic [23:0] instr_tag_o;
logic instr_valid_o;
logic [31:0] imm_o; 
logic [31:0] rs1_out_o;
logic [31:0] rs2_out_o;
logic [31:0] alu_out_o;
logic [31:0] br_en_o;
logic [31:0] mem_rdata_o;
logic [4:0] rs1_o;
logic [4:0] rs2_o;
rv32i_control_word cw_o;
logic [1:0] btb_flag_o;

generate
    if (has_pc_out) begin 
        register pc(
            .*,
            .in(pc_out_i),
            .out(pc_out_o)
        );
    end

    if (has_instr_data) begin 
        register instr_data(
            .*,
            .in(instr_data_i),
            .out(instr_data_o)
        );

        register #(24) instr_tag(
            .*,
            .in(instr_tag_i),
            .out(instr_tag_o)
        );

        register #(1) instr_valid(
            .*,
            .in(instr_valid_i),
            .out(instr_valid_o)
        );
    end

    if (has_imm) begin 
        register imm(
            .*,
            .in(imm_i),
            .out(imm_o)
        );
    end

    if (has_rs1_out) begin 
        register rs1(
            .*,
            .in(rs1_out_i),
            .out(rs1_out_o)
        );
    end

    if (has_rs2_out) begin 
        register rs2(
            .*,
            .in(rs2_out_i),
            .out(rs2_out_o)
        );
    end

    if (has_alu_out) begin 
        register alu_out(
            .*,
            .in(alu_out_i),
            .out(alu_out_o)
        );
    end

    if (has_br_en) begin 
        register br_en(
            .*,
            .in(br_en_i),
            .out(br_en_o)
        );
    end

    if (has_cw) begin 
        register #($bits(rv32i_control_word)) cw(
            .*,
            .in(cw_i),
            .out(cw_o)
        );
    end

    if (has_mem_rdata) begin 
        register rdata(
            .*,
            .in(mem_rdata_i),
            .out(mem_rdata_o)
        );
    end

    if (has_rs1) begin 
        register #(5) rs1(
            .*,
            .in(rs1_i),
            .out(rs1_o)
        );
    end

    if (has_rs2) begin 
        register #(5) rs2(
            .*,
            .in(rs2_i),
            .out(rs2_o)
        );
    end

    if (has_btb_flag) begin 
        register #(2) btb_flag(
            .*,
            .in(btb_flag_i),
            .out(btb_flag_o)
        );
    end

endgenerate

always_comb begin
    // IF/ID
    if_id.pc_out = pc_out_o;
    if_id.instr_data = instr_data_o;
    if_id.instr_tag = instr_tag_o;
    if_id.instr_valid = instr_valid_o;
    if_id.btb_flag = btb_flag_o;

    // ID/EX
    id_ex.pc_out = pc_out_o;
    id_ex.imm = imm_o;
    id_ex.rs1_out = rs1_out_o;
    id_ex.rs2_out = rs2_out_o;
    id_ex.cw = cw_o;
    id_ex.rs1 = rs1_o;
    id_ex.rs2 = rs2_o;

    // EX/MEM
    ex_mem.pc_out = pc_out_o;
    ex_mem.rs2_out = rs2_out_o;
    ex_mem.alu_out = alu_out_o;
    ex_mem.br_en = br_en_o;
    ex_mem.cw = cw_o;
    ex_mem.rs2 = rs2_o;

    // MEM/WB
    mem_wb.pc_out = pc_out_o;
    mem_wb.alu_out = alu_out_o;
    mem_wb.br_en = br_en_o;
    mem_wb.cw = cw_o;
    mem_wb.mem_rdata = mem_rdata_o;
end

endmodule : stage_reg
