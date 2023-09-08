module stage_execute
import rv32i_types::*;
(
    input clk,
    input rst,
    input logic [31:0] pc_out_i,
    input logic [31:0] rs1_out,
    input logic [31:0] rs2_out,
    input logic [31:0] imm,
    input rv32i_control_word cw,
    // from forwarding unit 
    input rv32i_word f_rs1,
    input rv32i_word f_rs2,
    input logic f_alumux1,
    input logic f_alumux2,
    input logic f_cmpmux,

    // to stage registers
    output logic [31:0] alu_out,
    output logic [31:0] br_en,
    output logic [31:0] br_out,
    output pcmux::pcmux_sel_t ex_pcmux_sel,   // new
    output logic mispredict,
    output rv32i_opcode ex_opcode,
    output logic [31:0] pc_out_o,

    output logic update,
    output logic update_btb,

    output rv32i_control_word cw_o
);

logic [31:0] alumux1_out;
logic [31:0] alumux2_out;
logic [31:0] cmpmux_out;
logic bit_br_en;
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
cmpmux::cmpmux_sel_t cmpmux_sel;

assign alumux1_sel = (f_alumux1 & (cw.alumux1_sel == alumux::rs1_out)) ? alumux::f_rs1 : cw.alumux1_sel;
assign alumux2_sel = (f_alumux2 & (cw.alumux2_sel == alumux::rs2_out)) ? alumux::f_rs2 : cw.alumux2_sel;
assign cmpmux_sel = (f_cmpmux & (cw.cmpmux_sel == cmpmux::rs2_out)) ? cmpmux::f_rs2 : cw.cmpmux_sel;
assign ex_opcode = cw.opcode;
assign pc_out_o = pc_out_i;

alu alu(
    .aluop(cw.aluop),
    .a(alumux1_out),
    .b(alumux2_out),
    .f(alu_out)
);

cmp cmp(
    .funct3(cw.cmpop), // cmpop
    .a(f_alumux1 ? f_rs1 : rs1_out), 
    .b(cmpmux_out), 
    .br_en(bit_br_en)
);

assign br_en = {31'b0, bit_br_en}; 

always_comb begin 

    // calculate Branch destination address
    br_out = imm + pc_out_i;
    
    // default 
    mispredict = 1'b0;
    ex_pcmux_sel = cw.pcmux_sel;
    update = 1'b0;
    update_btb = 1'b0;

    if (cw.opcode == op_br && cw.load_pc)   // if instr is br, need to update predictor 
        update = 1'b1;
    
    if (cw.opcode == op_br && cw.load_pc && cw.btb_flag[1] == 0)  // br but not in btb, need to update btb
        update_btb = 1'b1;

    // check whether mispredict
    if (cw.opcode == op_br && cw.load_pc) begin
        if (bit_br_en && ~cw.btb_flag[0]) begin
            mispredict = 1'b1;
            ex_pcmux_sel = pcmux::br_out;
           
        end
        if (~bit_br_en && cw.btb_flag[0]) begin
            mispredict = 1'b1;
            ex_pcmux_sel = pcmux::ex_pc_plus4;
        end
    end

    if (((cw.opcode == op_jal) || (cw.opcode == op_jalr)) && cw.load_pc) begin
        mispredict = 1'b1;
        unique case(cw.pcmux_sel)
            pcmux::alu_out: ex_pcmux_sel = pcmux::alu_out;
            pcmux::alu_mod2: ex_pcmux_sel = pcmux::alu_mod2;
            default:;
        endcase
    end    

    // // output pc_select signal
    // unique case(cw.pcmux_sel)
    // 	pcmux::pc_plus4: ex_pcmux_sel = pcmux::pc_plus4;
    //     pcmux::alu_out: ex_pcmux_sel = pcmux::alu_out;
    //     pcmux::alu_mod2: ex_pcmux_sel = pcmux::alu_mod2;
    //     pcmux::br_out: ex_pcmux_sel = (bit_br_en) ?  pcmux::br_out : pcmux::pc_plus4;
    //     default:;
    // endcase

    unique case(alumux1_sel) 
        alumux::rs1_out: alumux1_out = rs1_out;
        alumux::pc_out: alumux1_out = pc_out_i;
        alumux::zero: alumux1_out = 32'b0;
        alumux::f_rs1: alumux1_out = f_rs1;
        default: ;
    endcase

    unique case(alumux2_sel) 
        alumux::imm: alumux2_out = imm;
        alumux::rs2_out: alumux2_out = rs2_out;
        alumux::f_rs2: alumux2_out = f_rs2;
        default: ;
    endcase

    unique case(cmpmux_sel) 
        cmpmux::rs2_out: cmpmux_out = rs2_out;
        cmpmux::imm: cmpmux_out = imm;
        cmpmux::f_rs2: cmpmux_out = f_rs2;
        default: ;
    endcase
end

always_comb begin : monitor
    // set mem_rdata/mem_wdata
    cw_o = cw;
    if (mispredict) begin 
        cw_o.monitor_info.pc_wdata = br_out; // new pc
    end
end

endmodule : stage_execute
