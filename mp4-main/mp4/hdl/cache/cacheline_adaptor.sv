module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

function rd_dram(int i);
    address_o = address_i;
    read_o = 1'b1; // assert read_o
    write_o = 1'b0;

    line_o[64*i +: 64] = burst_i; // read bursts into line_o
endfunction

function wr_dram(int i);
    address_o = address_i;
    write_o = 1'b1; // assert write_o
    read_o = 1'b0;

    burst_o = line_i[64*i +: 64];
endfunction

function reset; // set all outputs to default
    // to llc
    line_o = 256'b0;
    resp_o = 1'b0;

    // to memory
    burst_o = 64'b0;
    address_o = 32'b0;
    read_o = 1'b0;
    write_o = 1'b0;
endfunction

enum int unsigned {
    /* List of states */
    WAIT,
    R0, R1, R2, R3,
    W0, W1, W2, W3,
    RESP
} state, next_state;

always_comb
begin : next_state_logic
    case(state) 
        WAIT: begin 
            case ({read_i, write_i, read_o, write_o})
                4'b1000: next_state = R0;
                4'b0100: next_state = W0;
                default: next_state = WAIT;
            endcase
        end

        R0: begin 
            if (resp_i) next_state = R1;
            else next_state = R0;
        end
        R1: begin 
            if (resp_i) next_state = R2;
            else next_state = R1;
        end
        R2: begin 
            if (resp_i) next_state = R3;
            else next_state = R2;
        end
        R3: begin 
            if (resp_i) next_state = RESP;
            else next_state = R3;
        end

        W0: begin 
            if (resp_i) next_state = W1;
            else next_state = W0;
        end
        W1: begin 
            if (resp_i) next_state = W2;
            else next_state = W1;
        end
        W2: begin 
            if (resp_i) next_state = W3;
            else next_state = W2;
        end
        W3: begin 
            if (resp_i) next_state = RESP;
            else next_state = W3;
        end

        RESP: next_state = WAIT;
    endcase
end

always_comb
begin : state_actions
    read_o = 1'b0;
    write_o = 1'b0;
    resp_o = 1'b0;
    case(state) 
        R0: rd_dram(0);
        R1: rd_dram(1);
        R2: rd_dram(2);
        R3: rd_dram(3);

        W0: wr_dram(0); 
        W1: wr_dram(1); 
        W2: wr_dram(2); 
        W3: wr_dram(3); 
        RESP: resp_o = 1'b1;
        WAIT: ;
    endcase
end

always_ff @(posedge clk, negedge reset_n) begin
    // The `n` in the `reset_n_i` means the reset signal is active low
    if (~reset_n) 
        state <= WAIT;
    else  
        state <= next_state;
end

endmodule : cacheline_adaptor
