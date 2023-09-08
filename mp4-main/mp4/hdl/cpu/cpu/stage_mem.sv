module stage_mem
import rv32i_types::*;
(
    input clk,
    input rst,

    input rv32i_word mem_wdata_i,
    input rv32i_control_word cw,
    input rv32i_word mem_address_i,
    
    // forwarding
    input logic f_wmux,
    input logic [31:0] f_wdata,
    input logic [31:0] pc_out_i,
    
    output rv32i_word mem_wdata_o,
    output rv32i_word mem_address_o,
    output logic mem_read,
    output logic mem_write,
    output logic [3:0] mem_byte_enable,
    output rv32i_control_word cw_o,
    output logic [31:0] pc_out_o
);

load_funct3_t load_funct3;
store_funct3_t store_funct3;

assign load_funct3 = load_funct3_t'(cw.funct3);
assign store_funct3 = store_funct3_t'(cw.funct3);

logic [31:0] mem_data, f_data;
assign mem_data = (mem_wdata_i  << 8*mem_address_i[1:0]) & ({{8{mem_byte_enable[3]}}, {8{mem_byte_enable[2]}}, {8{mem_byte_enable[1]}}, {8{mem_byte_enable[0]}}});
assign f_data = (f_wdata  << 8*mem_address_i[1:0]) & ({{8{mem_byte_enable[3]}}, {8{mem_byte_enable[2]}}, {8{mem_byte_enable[1]}}, {8{mem_byte_enable[0]}}});

assign mem_wdata_o = (f_wmux) ? f_data : mem_data;
assign mem_address_o = {mem_address_i [31:2], 2'b00};
assign mem_read = cw.mem_read;
assign mem_write = cw.mem_write;
assign pc_out_o = pc_out_i;

always_comb
begin 
    case (cw.opcode)
        op_load: begin
            case (load_funct3)
                lw: mem_byte_enable = 4'b1111;
                lh, lhu: mem_byte_enable = 4'b0011 << mem_address_i[1:0];
                lb, lbu: mem_byte_enable = 4'b0001 << mem_address_i[1:0];
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: mem_byte_enable = 4'b1111;
                sh: mem_byte_enable = 4'b0011 << mem_address_i[1:0];
                sb: mem_byte_enable = 4'b0001 << mem_address_i[1:0];
            endcase
        end

        default:;
    endcase
end

logic [3:0] rmask, wmask;
logic trap;

always_comb begin : monitor
    // set mem_rdata/mem_wdata
    cw_o = cw;
    cw_o.monitor_info.mem_addr = mem_address_o;
    
    if (cw_o.opcode == op_store) begin 
        cw_o.monitor_info.mem_wdata = mem_wdata_o;
    end

    // set rmask, wmask, trap
    case(cw.opcode) 
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3_t'(cw.funct3))
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = '1;
            endcase
        end
        
        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lh, lhu: rmask = 4'b0011 << mem_address_i[1:0];
                lb, lbu: rmask = 4'b0001 << mem_address_i[1:0];
                default: trap = '1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                sh: wmask = 4'b0011 << mem_address_i[1:0];
                sb: wmask = 4'b0001 << mem_address_i[1:0];
                default: trap = '1;
            endcase
        end
        default: trap = '1;
    endcase

    cw_o.monitor_info.mem_rmask = rmask;
    cw_o.monitor_info.mem_wmask = wmask;
    cw_o.monitor_info.trap = trap;
end

endmodule : stage_mem
