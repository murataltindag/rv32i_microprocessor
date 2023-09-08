module forwarding_unit
import rv32i_types::*;
(
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] ex_mem_rs2,
    input rv32i_control_word ex_mem_cw,
    input rv32i_control_word mem_wb_cw,
    input logic [31:0] ex_mem_alu_out,
    input logic [31:0] ex_mem_br_en,
    input rv32i_word mem_wb_data,
    input rv32i_opcode ex_opcode,

    // to stage registers
    output logic [31:0] f_rs1,
    output logic [31:0] f_rs2,
    output logic [31:0] f_wdata, 
    output logic f_alumux1, 
    output logic f_alumux2, 
    output logic f_wmux,
    output logic f_cmpmux
);

// EX Hazards (i.e. EX/MEM -> EX)
always_comb begin
    f_alumux1 = 1'b0;
    f_alumux2 = 1'b0; 
    f_wmux = 1'b0;
    f_cmpmux = 1'b0;

    // all i types
    if (~((ex_opcode == op_lui) | (ex_opcode == op_auipc))) begin 
        if (    ex_mem_cw.load_regfile &
                ((ex_mem_cw.rd == rs1) & (rs1 != 5'b0)) & 
                ex_mem_cw.opcode != op_load) begin
                f_alumux1 = 1'b1; 
                case(ex_mem_cw.wb_sel)
                    wbmux::alu_out: f_rs1 = ex_mem_alu_out;
                    wbmux::br_en: f_rs1 = ex_mem_br_en;
                    default: ;
                endcase
            end
    end
    // all i types & u types
    if (~((ex_opcode == op_lui) | (ex_opcode == op_auipc) | 
        (ex_opcode == op_jalr) | (ex_opcode == op_load) | 
        (ex_opcode == op_imm))) begin 
        if (    ex_mem_cw.load_regfile &
                ((ex_mem_cw.rd == rs2) & (rs2 != 5'b0)) & 
                ex_mem_cw.opcode != op_load) begin
                f_alumux2 = 1'b1; 
                f_cmpmux = 1'b1;
                case(ex_mem_cw.wb_sel)
                    wbmux::alu_out: f_rs2 = ex_mem_alu_out;
                    wbmux::br_en: f_rs2 = ex_mem_br_en;
                    default: ;
                endcase
        end
    end
// MEM Hazards (i.e. MEM/WB -> EX)
// all u types
    if (~((ex_opcode == op_lui) | (ex_opcode == op_auipc))) begin 
        if (    mem_wb_cw.load_regfile & 
                ~(ex_mem_cw.load_regfile & ((ex_mem_cw.rd == rs1))) &
                ((mem_wb_cw.rd == rs1) & (rs1 != 5'b0))
              ) begin 
            f_alumux1 = 1'b1; 
            f_rs1 = mem_wb_data;
          end
    end
    // all i types & u types
    if (~((ex_opcode == op_lui) | (ex_opcode == op_auipc) | 
        (ex_opcode == op_jalr) | (ex_opcode == op_load) | 
        (ex_opcode == op_imm))) begin 
          if (    mem_wb_cw.load_regfile & 
                  ~(ex_mem_cw.load_regfile & ((ex_mem_cw.rd == rs2) & (rs2 != 5'b0))) &
                  ((mem_wb_cw.rd == rs2) & (rs2 != 5'b0))
                ) begin 
              f_alumux2 = 1'b1; 
              f_cmpmux = 1'b1;
              f_rs2 = mem_wb_data;
            end 
        end
  // WB -> MEM LD/ST Hazard
if (
  (mem_wb_cw.opcode == op_load) &   // load followed by store 
  (ex_mem_cw.opcode == op_store) & 
  (ex_mem_rs2 == mem_wb_cw.rd) & // wdata is wbdata
  (mem_wb_cw.rd) // not reg 0
) begin 
  f_wmux = 1'b1;
  f_wdata = mem_wb_data;
end
end



endmodule : forwarding_unit
