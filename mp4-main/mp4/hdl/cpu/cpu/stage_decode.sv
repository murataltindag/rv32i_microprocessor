module stage_decode
import rv32i_types::*;
(
    input clk,
    input rst,
    input logic [31:0] pc_out_i,
    input logic [31:0] instr_data,
    input logic [23:0] instr_tag,
    input logic instr_valid,
    input logic [31:0] wbmux_out,
    input rv32i_control_word cw_i,
    input rv32i_control_word id_ex_cw,
    input logic decode_cw_sel,   
    input logic [1:0] btb_flag, // new

    // to stage registers
    output logic [31:0] imm,
    output logic [31:0] pc_out,
    output logic [31:0] rs1_out,
    output logic [31:0] rs2_out,
    output rv32i_control_word cw,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic decode_stall 
    //output decode_predict_pc  // new  
);

logic [2:0] funct3; 
logic [6:0] funct7;
rv32i_opcode opcode;
logic [31:0] i_imm;
logic [31:0] s_imm;
logic [31:0] b_imm;
logic [31:0] u_imm;
logic [31:0] j_imm;
// logic [4:0] rs1;
// logic [4:0] rs2;
logic [4:0] rd;
logic reset;
reg count;
logic stall;

rv32i_word real_pc;
assign real_pc = pc_out + 32'ha0;

assign decode_stall = stall;

regfile regfile(
    .clk    (clk),
    .rst    (rst),
    .load   (cw_i.load_regfile),
    .in     (wbmux_out),
    .src_a  (rs1), .src_b  (rs2), .dest   (cw_i.rd),
    .reg_a  (rs1_out), .reg_b (rs2_out)
);

ir IR(
    .clk    (clk),
    .rst    (rst),
    .in     (instr_data),
    .*
);

/*
register pc_reg_dec(
    .clk    (clk),
    .rst    (rst),
    .load   (load_ir),
    .in     (pc_out_i),
    .out    (pc_out)
);
*/

function void set_defaults();
    cw.opcode = opcode;

    cw.aluop =alu_add;
    cw.cmpop = funct3;
    
    cw.alumux1_sel = alumux::rs1_out;
    cw.alumux2_sel = alumux::imm;
    cw.cmpmux_sel = cmpmux::rs2_out;
    cw.pcmux_sel = pcmux::pc_plus4;

    cw.load_regfile = '0;
    cw.load_pc = '0;
            
    cw.mem_read = '0;
    cw.mem_write = '0;

    cw.rd = rd;
    cw.wb_sel = wbmux::alu_out;
    cw.funct3 = funct3;

    cw.btb_flag = '0;
endfunction

function void set_monitor() ;
// monitor info 
    cw.monitor_info.trap = '0;
    cw.monitor_info.inst = instr_data;
    cw.monitor_info.rs1_addr = rs1;
    cw.monitor_info.rs2_addr = rs2;
    cw.monitor_info.rs1_rdata = rs1_out;
    cw.monitor_info.rs2_rdata = rs2_out;
    cw.monitor_info.rd_wdata = '0;
    cw.monitor_info.pc_rdata = pc_out_i;
    cw.monitor_info.pc_wdata = pc_out_i + 4; // default, change on misprediction
    
    cw.monitor_info.mem_addr = '0;
    cw.monitor_info.mem_rmask = '0;
    cw.monitor_info.mem_wmask = '0;
    cw.monitor_info.mem_rdata = '0;
    cw.monitor_info.mem_wdata = '0;
endfunction

always_comb begin 
    // default cw assigment
    set_defaults();
    set_monitor();

    // setting imm output according to opcode
    unique case(opcode) 
        op_lui, op_auipc: imm = u_imm;
        op_jal: imm = j_imm;
        op_jalr, op_load, op_imm: imm = i_imm;
        op_br: imm = b_imm;
        op_store: imm = s_imm;
        op_reg: imm = '0;
        default: ;
    endcase

    // forward pc
    pc_out = pc_out_i;

    // generate next pc if predict taken 
    /*
    unique case(opcode)
        op_br: decode_predict_pc = b_imm + pc_out;
        op_jal, op_jalr:
        default:
    endcase
    */

    // FINISH CW creation based on opcode
    unique case(opcode) 
        op_lui: begin 
            cw.alumux1_sel = alumux::zero;
            cw.load_regfile = 1'b1;
        end
        op_auipc: begin 
            cw.load_regfile = 1'b1;
	    cw.alumux1_sel = alumux::pc_out;
        end
        op_jal: begin 
            cw.alumux1_sel = alumux::pc_out;
            cw.pcmux_sel = pcmux::alu_out;
            cw.load_pc = 1'b1;
            cw.load_regfile = 1'b1;
	    cw.wb_sel = wbmux::pc_plus4;
        end
        op_jalr: begin 
            cw.pcmux_sel = pcmux::alu_mod2;
            cw.load_pc = 1'b1;
            cw.load_regfile = 1'b1;
	    cw.wb_sel = wbmux::pc_plus4;
        end
        op_br: begin 
            cw.pcmux_sel = pcmux::br_out;
            cw.load_pc = 1'b1;
            cw.btb_flag = btb_flag;
        end
        op_load: begin 
            cw.mem_read = 1'b1;
            cw.load_regfile = 1'b1;
	    unique case (load_funct3_t'(funct3))
            lw: cw.wb_sel = wbmux::lw;
            lb: cw.wb_sel = wbmux::lb;
            lbu: cw.wb_sel = wbmux::lbu;
            lh: cw.wb_sel = wbmux::lh;
            lhu: cw.wb_sel = wbmux::lhu;
            default: ;
        endcase
        end
        op_store: begin 
            cw.mem_write = 1'b1;
        end
        op_imm: begin 
            cw.load_regfile = 1'b1;
            unique case(arith_funct3_t'(funct3))
                default: begin   // defaut handles add, xor, and, or, sll
                    cw.aluop = funct3;
                    cw.load_regfile = 1'b1;
                end

                slt:begin
                    cw.cmpop = cmp_lt;
                    cw.cmpmux_sel = cmpmux::imm;
                    cw.wb_sel = wbmux::br_en;
                    cw.load_regfile = 1'b1;
                end
                sltu:begin
                    cw.cmpop = cmp_ltu;
                    cw.cmpmux_sel = cmpmux::imm;
                    cw.wb_sel = wbmux::br_en;
                    cw.load_regfile = 1'b1;
                end

                sr:begin
                    if (funct7[5] == 1'b1) begin    // SRA
                        cw.aluop =alu_sra;
                        cw.load_regfile = 1'b1;
                    end else begin
                        cw.aluop =alu_srl;  // SRL
                        cw.load_regfile = 1'b1;
                    end
                end
             endcase
        end
        op_reg: begin 
           unique case(arith_funct3_t'(funct3))
                default: begin   // defaut handles xor, and, or, sll
                    cw.aluop = funct3;
                    cw.load_regfile = 1'b1;
		    cw.alumux2_sel = alumux::rs2_out;
                end

                add:begin
                    if (funct7[5] == 1'b1) begin    // SUB
                        cw.aluop =alu_sub;
                        cw.load_regfile = 1'b1;
                        cw.alumux2_sel = alumux::rs2_out;
                    end else begin
                        cw.aluop =alu_add;  // ADD
                        cw.load_regfile = 1'b1;
                        cw.alumux2_sel = alumux::rs2_out;
                    end
                end

                slt:begin
                    cw.cmpop = cmp_lt;
                    cw.wb_sel = wbmux::br_en;
                    cw.alumux2_sel = alumux::rs2_out;
                    cw.load_regfile = 1'b1;
                end
                sltu:begin
                    cw.cmpop = cmp_ltu;
                    cw.wb_sel = wbmux::br_en;
                    cw.alumux2_sel = alumux::rs2_out;
                    cw.load_regfile = 1'b1;
                end

                sr:begin
                    if (funct7[5] == 1'b1) begin    // SRA
                        cw.aluop =alu_sra;
                        cw.load_regfile = 1'b1;
                        cw.alumux2_sel = alumux::rs2_out;
                    end else begin
                        cw.aluop =alu_srl;  // SRL
                        cw.load_regfile = 1'b1;
                        cw.alumux2_sel = alumux::rs2_out;
                    end
                end
             endcase
        end
        default: ;  // use default cw 
    endcase

    // mask part of cw to insert bubble to the next stage
    if (decode_cw_sel == 1'b1) begin
        set_defaults();
        cw.opcode = op_imm;
    end
end

always_comb begin     // detect read after load and jump
    stall = 1'b0;
    if ((id_ex_cw.mem_read) && ((id_ex_cw.rd == rs1) || (id_ex_cw.rd == rs2))
         && (opcode != op_store)) 
        // stall 1 cycle
        stall = 1'b1;

    // if (count)
    //     stall = 1'b0;   
end

always_comb begin 
    // mux for reset input of counter
    if (stall)
        reset = 1'b0;
    else
        reset = 1'b1;
end

always@(posedge clk) begin
    if(reset)
        count <= 1'b0;
    else
        count <= count + '1;
end

endmodule : stage_decode