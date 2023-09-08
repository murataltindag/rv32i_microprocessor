module lhbp_unit
import rv32i_types::*;
#(
    parameter l_idx = 4,
    parameter pht_row = 2**l_idx
)
(
    input clk,  
    input rst,  
    input [31:0] if_pc_in,
    input [31:0] ex_pc_in,
    input logic update,
    input logic prev_mispredict,
    
    output logic p_tnt
);

typedef enum bit [1:0] {
    st = 2'b00,
    wt = 2'b01,
    wn = 2'b10,
    sn = 2'b11
} bp_state_t;

bp_state_t next_state;
bp_state_t current_state;
bp_state_t updating_state;
bp_state_t pht [pht_row];

logic [l_idx-1:0] if_pht_idx;
logic [l_idx-1:0] ex_pht_idx;

always_comb begin
    /// indexing into pht using pc input for ex stage updating pht
    ex_pht_idx = ex_pc_in[l_idx + 2 - 1 : 2];
    updating_state = pht[ex_pht_idx];

    // updating pht using inputs from ex stage
    if (update) begin
        unique case(updating_state)
            st: begin
                if (prev_mispredict)
                    next_state = wt;
                else
                    next_state = st;
            end
            wt: begin
                if (prev_mispredict)
                    next_state = wn;
                else
                    next_state = st;
            end
            wn: begin
                if (prev_mispredict)
                    next_state = wt;
                else
                    next_state = sn;
            end
            sn: begin
                if (prev_mispredict)
                    next_state = wn;
                else
                    next_state = sn;
            end
            default: ;
        endcase
    end

    // indexing into pht using pc input for if stage prediction
    if_pht_idx = if_pc_in[l_idx + 2 - 1 : 2];
    current_state = pht[if_pht_idx];

   // making prediction based on current state
   unique case(next_state)
        st, wt: p_tnt = 1'b1;
        sn, wn: p_tnt = 1'b0;
        default: ;
    endcase
end

// updateing pht
always@(posedge clk) begin
    if(rst) begin
        for (int i=0; i < pht_row; ++i)
            pht[i] <= wt;
    end
    else if (update) begin
        pht[ex_pht_idx] <= next_state;
    end
end

endmodule : lhbp_unit