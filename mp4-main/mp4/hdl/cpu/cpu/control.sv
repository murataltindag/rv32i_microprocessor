module control_unit
import rv32i_types::*;
(
    input clk,  
    input rst,  
    input logic decode_stall,
    input logic if_stall,
    input logic mem_stall,
    input logic mispredict,
    input pcmux::pcmux_sel_t ex_pcmux_sel,

    input logic [1:0] btb_flag,   // new

    // to stage registers
    output logic load_if_id,
    output logic load_id_ex,
    output logic load_ex_mem,
    output logic load_mem_wb,

    // to muxes
    output ifmux::ifmux_sel_t ifmux_sel,  
    output logic decode_cw_sel,

    // to pc
    output logic load_pc,
    output pcmux::pcmux_sel_t pcmux_sel
    //output logic [31:0] correct_pc

    //output logic load_ir
);

function void set_defaults();
    load_if_id = 1'b1;
    load_id_ex = 1'b1;
    load_ex_mem = 1'b1;
    load_mem_wb = 1'b1;

    ifmux_sel = ifmux::instr_data; 
    decode_cw_sel = 1'b0; 

    load_pc = 1'b1;
    pcmux_sel = pcmux::pc_plus4; 

    //load_ir = 1;
endfunction

always_comb begin   
    // set default control signals
    set_defaults();

    if (btb_flag == 2'b11)
        pcmux_sel = pcmux::btb_pc;

    if (if_stall && ~decode_stall && ~mispredict && ~mem_stall) begin  // stall casued by fetch
        load_pc = 1'b0;
        ifmux_sel = ifmux::no_op;
    end

    if (decode_stall && ~mispredict && ~mem_stall) begin  // stall casued by read after load
        load_pc = 1'b0;
        load_if_id = 1'b0;
        decode_cw_sel = 1'b1;
    end

    if (mispredict && ~mem_stall && ~if_stall) begin  // handle misprediction
        // flush
        ifmux_sel = ifmux::no_op;   
        decode_cw_sel = 1'b1; 

        // output correct pc_mux select
        pcmux_sel = ex_pcmux_sel;
    end  

    if (mispredict && ~mem_stall && if_stall) begin 
        load_pc = 1'b0;
        load_if_id = '0;
        load_id_ex = '0;
        load_ex_mem = 1'b0;
        load_mem_wb = 1'b0;

    end

    if (mem_stall) begin   // stall caused by MEM stage
        // stall all 5 stages
        load_pc = 1'b0;
        load_if_id = 1'b0;
        //load_ir = 0;
        load_id_ex = 1'b0;
        load_ex_mem = 1'b0;
        load_mem_wb = 1'b0;
    end
    
    if (rst) begin 
        load_pc = 1'b0;
    end

end

endmodule : control_unit
