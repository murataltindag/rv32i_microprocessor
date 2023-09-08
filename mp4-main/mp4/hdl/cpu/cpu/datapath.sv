module datapath
import rv32i_types::*;
(
    input clk,  
    input rst,  
    // change after CP1
    input 					instr_mem_resp,
    input rv32i_word 	instr_mem_rdata,
	input 					data_mem_resp,
    input rv32i_word 	data_mem_rdata, 

    output logic 			instr_read,
	output rv32i_word 	instr_mem_address,
    output logic 			data_read,
    output logic 			data_write,
    output logic [3:0] 	data_mbe,
    output rv32i_word 	data_mem_address,
    output rv32i_word 	data_mem_wdata
);


// IF STAGE
logic load_pc;
pcmux::pcmux_sel_t pcmux_sel; 
logic [31:0] br_out;
logic [31:0] pc_out;
rv32i_if_id_t if_id;
logic [31:0] alu_out;
rv32i_word wb_data;
logic [31:0] ex_pc;

rv32i_word instr_data;  
ifmux::ifmux_sel_t ifmux_sel;  // from control to mux

logic [31:0] predicted_pc;  // from btb

// control signals
logic if_stall; 
logic mem_stall;
pcmux::pcmux_sel_t ex_pcmux_sel;
logic mispredict;
logic load_if_id;
logic load_id_ex;
logic load_ex_mem;
logic load_mem_wb;
rv32i_ex_mem_t ex_mem;
rv32i_mem_wb_t mem_wb;


stage_fetch fetch(
    .clk(clk),
    .rst(rst),
    .load_pc(load_pc),
    .pcmux_sel(pcmux_sel),
    .alu_out(alu_out),
    .br_out(br_out),
    .predicted_pc(predicted_pc),
    .ex_pc(ex_pc),
    
    .pc_out(pc_out),
    .instr_mem_address(instr_mem_address),
    .instr_read(instr_read)
);

rv32i_opcode ex_opcode;

// setting control signals
always_comb begin
    // mux in IF for stalling 
     unique case(ifmux_sel) 
        ifmux::instr_data: instr_data = instr_mem_rdata;
        ifmux::no_op: instr_data = 32'h00000013; 
        default: ;
    endcase

    // determine whether need to stall IF
    if (instr_mem_resp || rst) 
        if_stall = 1'b0;
    else
        if_stall = 1'b1;

    // determine whether need to stall at MEM
    if (~data_mem_resp && (ex_mem.cw.mem_read == '1 || ex_mem.cw.mem_write == '1))
        mem_stall = 1'b1;
    else
        mem_stall = 1'b0;
end

logic [1:0] btb_flag;  // from btb

// if/id
stage_reg #(
    .has_pc_out(1'b1), 
    .has_instr_data(1'b1),
    .has_btb_flag(1'b1)
)
if_id_reg (
    .clk(clk),
    .rst(rst),
    .load(load_if_id), 
    .pc_out_i(pc_out),
    .instr_data_i(instr_data), // modified
    .btb_flag_i(btb_flag),
    .if_id(if_id)
);

// stage decode
logic [31:0] rs1_out;
logic [31:0] rs2_out;
logic [31:0] imm;
logic [31:0] decode_pc;
rv32i_id_ex_t id_ex;
rv32i_control_word cw;
logic [4:0] rs1;
logic [4:0] rs2;
logic decode_stall;
logic decode_cw_sel;

stage_decode decode
(
    .clk(clk),
    .rst(rst),
    .pc_out_i(if_id.pc_out),
    .instr_data(if_id.instr_data),
    .instr_tag(if_id.instr_tag),
    .instr_valid(if_id.instr_valid),
    .wbmux_out(wb_data), 
    .cw_i(mem_wb.cw),
    .id_ex_cw(id_ex.cw),
    .decode_cw_sel(decode_cw_sel), 
    .btb_flag(if_id.btb_flag),

    // to stage registers
    .imm(imm),
    .pc_out(decode_pc),
    .rs1_out(rs1_out),
    .rs2_out(rs2_out),
    .cw(cw),
    .rs1(rs1),
    .rs2(rs2),

    // to control unit
    .decode_stall(decode_stall)   
);

// ID/EX
stage_reg #(
    .has_pc_out(1'b1),
    .has_imm(1'b1),
    .has_rs1_out(1'b1), 
    .has_rs2_out(1'b1),
    .has_cw(1'b1),
    .has_rs1(1'b1),
    .has_rs2(1'b1)
)
id_ex_reg (
    .clk(clk),
    .rst(rst),
    .load(load_id_ex), 
    .pc_out_i(decode_pc),  
    .imm_i(imm),
    .rs1_i(rs1),
    .rs2_i(rs2),
    .rs1_out_i(rs1_out),
    .rs2_out_i(rs2_out),
    .cw_i(cw),

    .id_ex(id_ex)
);

// stage ex
logic [31:0] br_en;
rv32i_word f_rs1;
rv32i_word f_rs2;
logic f_alumux1;
logic f_alumux2;
logic forward;
rv32i_control_word ex_cw;
logic f_cmpmux;
logic update;
logic update_btb;

stage_execute execute
(
    .clk(clk),
    .rst(rst),
    .pc_out_i(id_ex.pc_out),
    .rs1_out(id_ex.rs1_out),
    .rs2_out(id_ex.rs2_out),
    .imm(id_ex.imm),
    .cw(id_ex.cw),

    .f_rs1(f_rs1),
    .f_rs2(f_rs2),
    .f_alumux1(f_alumux1),
    .f_alumux2(f_alumux2),
    .f_cmpmux(f_cmpmux),

    // to stage registers
    .alu_out(alu_out),
    .br_en(br_en),
    .br_out(br_out),
    .ex_pcmux_sel(ex_pcmux_sel),
    .mispredict(mispredict),
    .ex_opcode(ex_opcode),
    .pc_out_o(ex_pc),
    .cw_o(ex_cw),

    .update(update),
    .update_btb(update_btb)
);

// EX/MEM
stage_reg #(
    .has_pc_out(1'b1),
    .has_alu_out(1'b1),
    .has_br_en(1'b1),
    .has_rs2_out(1'b1),
    .has_cw(1'b1),
    .has_rs2(1'b1)
)
ex_mem_reg (
    .clk(clk),
    .rst(rst),
    .load(load_ex_mem), 
    .pc_out_i(ex_pc),
    .rs2_i(id_ex.rs2),
    .alu_out_i(alu_out),
    .br_en_i(br_en),
    .rs2_out_i((f_alumux2) ? f_rs2 : id_ex.rs2_out), 
    .cw_i(ex_cw),

    .ex_mem(ex_mem)
);

logic f_wmux;
logic [31:0] f_wdata;
rv32i_control_word mem_cw;
logic [31:0] mem_pc;
// stage mem
stage_mem memory
(
    .clk(clk),
    .rst(rst),

    .pc_out_i(ex_mem.pc_out),
    .mem_wdata_i(ex_mem.rs2_out),
    .cw(ex_mem.cw),
    .mem_address_i(ex_mem.alu_out),
    
    .f_wmux(f_wmux),
    .f_wdata(f_wdata),

    .mem_wdata_o(data_mem_wdata),
    .mem_address_o(data_mem_address),
    .mem_read(data_read),
    .mem_write(data_write),
    .mem_byte_enable(data_mbe),
    .cw_o(mem_cw),
    .pc_out_o(mem_pc)
);
// MEM/WB 

stage_reg #(
    .has_pc_out(1'b1),
    .has_alu_out(1'b1),
    .has_br_en(1'b1),
    .has_cw(1'b1),
    .has_mem_rdata(1'b1)
)
mem_wb_reg (
    .clk(clk),
    .rst(rst),
    .pc_out_i(mem_pc),
    .load(load_mem_wb), 
    .alu_out_i(ex_mem.alu_out),
    .br_en_i(ex_mem.br_en),
    .cw_i(mem_cw),
    .mem_rdata_i(data_mem_rdata), // connect from memory

    .mem_wb(mem_wb)
);

// stage wb

stage_wb write_back
(
    .clk(clk),
    .rst(rst),

    .pc_out_i(mem_wb.pc_out),
    .mem_rdata(mem_wb.mem_rdata),
    .alu_out(mem_wb.alu_out),
    .br_en(mem_wb.br_en),
    .cw(mem_wb.cw),
    

    .wb_data(wb_data)
    
);

forwarding_unit fu(
    .rs1(id_ex.rs1),
    .rs2(id_ex.rs2),
    .ex_mem_rs2(ex_mem.rs2),
    .ex_mem_cw(ex_mem.cw),
    .mem_wb_cw(mem_wb.cw),
    .ex_mem_alu_out(ex_mem.alu_out),
    .ex_mem_br_en(ex_mem.br_en),
    .mem_wb_data(wb_data),
    .ex_opcode(ex_opcode),

    // to stage registers
    .f_rs1(f_rs1),
    .f_rs2(f_rs2), 
    .f_wdata(f_wdata),
    .f_alumux1(f_alumux1),
    .f_alumux2(f_alumux2),
    .f_wmux(f_wmux),
    .f_cmpmux(f_cmpmux)
);

control_unit cu(
    .clk(clk),  
    .rst(rst),  
    .decode_stall(decode_stall),
    .if_stall(if_stall),
    .mem_stall(mem_stall),
    .mispredict(mispredict),
    .ex_pcmux_sel(ex_pcmux_sel),
    .btb_flag(btb_flag),

    // to stage registers
    .load_if_id(load_if_id),
    .load_id_ex(load_id_ex),
    .load_ex_mem(load_ex_mem),
    .load_mem_wb(load_mem_wb),

    // to muxes
    .ifmux_sel(ifmux_sel),  
    .decode_cw_sel(decode_cw_sel),

    // to pc
    .load_pc(load_pc),
    .pcmux_sel(pcmux_sel)
);

logic p_tnt;

btb_unit btb(
    .clk(clk),  
    .rst(rst),

    .update(update),
    .update_btb(update_btb),
    .br_out(br_out),
    .p_tnt(p_tnt),

    .if_pc_in(pc_out),
    .ex_pc_in(ex_pc),
    
    .predicted_pc(predicted_pc),
    .btb_flag(btb_flag)
);

lhbp_unit lhbp(
   .clk(clk),  
   .rst(rst), 
   .if_pc_in(pc_out),
   .ex_pc_in(ex_pc),
   .update(update),
   .prev_mispredict(mispredict),
    
   .p_tnt(p_tnt)
);


/*****************************************************************************/
endmodule : datapath