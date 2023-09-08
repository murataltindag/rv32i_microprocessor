module stage_wb
import rv32i_types::*;
(
    input clk,
    input rst,
    input logic [31:0] pc_out_i,
    input logic [31:0] alu_out,
    input logic [31:0] br_en,
    input rv32i_word mem_rdata,
    input rv32i_control_word cw,

    // to stage registers
    output rv32i_word wb_data
);

rv32i_control_word cw_o;
rv32i_opcode wb_opcode;

assign wb_opcode = cw.opcode;

always_comb begin 
    unique case(cw.wb_sel) 
        wbmux::alu_out: wb_data = alu_out;
        wbmux::br_en: wb_data = br_en;
        wbmux::lw: wb_data = mem_rdata;
	wbmux::lh: case(alu_out[1:0])
            2'b00: wb_data = {{16{mem_rdata[15]}}, mem_rdata[15:0]};
            2'b01: wb_data = {{16{mem_rdata[23]}}, mem_rdata[23:8]};
            2'b10: wb_data = {{16{mem_rdata[31]}}, mem_rdata[31:16]};
            2'b11: wb_data = 32'b0;
        endcase
	wbmux::lhu: case(alu_out[1:0])
            2'b00: wb_data = {16'b0, mem_rdata[15:0]};
            2'b01: wb_data = {16'b0, mem_rdata[23:8]};
            2'b10: wb_data = {16'b0, mem_rdata[31:16]};
            2'b11: wb_data = 32'b0;
        endcase
	wbmux::lb: case(alu_out[1:0])
            2'b00: wb_data = {{24{mem_rdata[7]}}, mem_rdata[7:0]};
            2'b01: wb_data = {{24{mem_rdata[15]}}, mem_rdata[15:8]};
            2'b10: wb_data = {{24{mem_rdata[23]}}, mem_rdata[23:16]};
            2'b11: wb_data = {{24{mem_rdata[31]}}, mem_rdata[31:24]};
        endcase
	wbmux::lbu: case(alu_out[1:0])
            2'b00: wb_data = {24'b0, mem_rdata[7:0]};
            2'b01: wb_data = {24'b0, mem_rdata[15:8]};
            2'b10: wb_data = {24'b0, mem_rdata[23:16]};
            2'b11: wb_data = {24'b0, mem_rdata[31:24]};
        endcase
        wbmux::pc_plus4: wb_data = pc_out_i + 4;
        default: ;
    endcase
end

always_comb begin : monitor
    // set mem_rdata/mem_wdata
    cw_o = cw;
    cw_o.monitor_info.rd_wdata = wb_data;
    cw_o.monitor_info.mem_rdata = mem_rdata;
end

endmodule : stage_wb
