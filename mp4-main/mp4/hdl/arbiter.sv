module arbiter
import rv32i_types::*;
(
    input clk,
    input rst,

    input logic 	instr_read,
    input rv32i_word 	instr_mem_address,
    input logic 	data_read,
    input logic 	data_write,
    input logic [3:0] 	data_mbe,
    input rv32i_word 	data_mem_address,
    input logic [255:0]	data_mem_wdata,
    output logic		instr_mem_resp,
    output logic [255:0] instr_mem_rdata,
    output logic		data_mem_resp,
    output logic [255:0] data_mem_rdata, 


    //From physical memory
    input logic pmem_resp,
    input logic [255:0] pmem_rdata,

	//To physical memory
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output logic [255:0] pmem_wdata
);



enum int unsigned {
    /* List of states */
    instr,
    data
} state, next_state;

function void set_defaults();
    pmem_read = 1'b0;
    pmem_write = 1'b0;
    pmem_address = 32'b0;
    pmem_wdata = 256'b0;
    instr_mem_resp = 1'b0;
    instr_mem_rdata = 256'b0;
    data_mem_resp = 1'b0;
    data_mem_rdata = 256'b0; 
endfunction


always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
    case(state)
    instr: begin
        pmem_address = instr_mem_address;
        instr_mem_resp = pmem_resp;
        instr_mem_rdata = pmem_rdata;
        
        pmem_read = instr_read;
        pmem_write = 1'b0;
    end

    data: begin
        pmem_address = data_mem_address;
        data_mem_resp = pmem_resp;
        data_mem_rdata = pmem_rdata;
        pmem_wdata = data_mem_wdata;
        
        pmem_read = data_read;
        pmem_write = data_write;
      end
      endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any) for transitioning between states */
    case(state)
    instr: begin 
        if (~pmem_resp && instr_read) next_state = instr;
        else if (data_read || data_write) next_state = data;
        else next_state = instr;
    end

    data: begin 
        if (~pmem_resp && (data_read || data_write)) next_state = data;
        else if (instr_read) next_state = instr;
        else next_state = data;
    end
  endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    state <= next_state;
end


endmodule : arbiter
