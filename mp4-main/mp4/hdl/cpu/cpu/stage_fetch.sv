module stage_fetch
import rv32i_types::*;
(
    input clk,
    input rst,
    input load_pc,
    input pcmux::pcmux_sel_t pcmux_sel,
    input [31:0] alu_out,
    input [31:0] br_out,
    input [31:0] predicted_pc,  // new
    input [31:0] ex_pc, // new
    output logic [31:0] pc_out,
    output logic [31:0] instr_mem_address,
    output logic instr_read
);

logic [31:0] pcmux_out;
// logic [31:0] pc_out_;

pc_register pc(
    .clk(clk),
    .rst(rst),
    .load(load_pc),
    .in(pcmux_out),
    .out(pc_out)
);

always_comb
begin
    instr_read = 1'b1;
    instr_mem_address = pc_out;

    unique case(pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
        pcmux::alu_out: pcmux_out = alu_out;
        pcmux::alu_mod2: pcmux_out = alu_out & 32'hfffffffe;
        pcmux::br_out: pcmux_out = br_out;
        pcmux::btb_pc: pcmux_out = predicted_pc;
        pcmux::ex_pc_plus4: pcmux_out = ex_pc + 4;
        default:;
    endcase
end

endmodule : stage_fetch
