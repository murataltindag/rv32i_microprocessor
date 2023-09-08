module btb_unit #(
    parameter s_index = 4,
    parameter width = 1
)
(
    input clk,
    input rst,
    
    input logic update,
    input logic update_btb,
    input logic [31:0] br_out,
    input logic p_tnt,
    
    input logic [31:0] if_pc_in,
    input logic [31:0] ex_pc_in,

    output logic [31:0] predicted_pc,
    output logic [1:0] btb_flag
);

localparam num_sets = 2**s_index;

typedef struct packed {
    logic [31:0] br_pc;
    logic [31:0] target_pc;
    logic predict;
} btb_entry_t;

btb_entry_t btb [num_sets-1:0];

// getting the idx into btb
logic [s_index-1:0] if_idx;
logic [s_index-1:0] ex_idx;

assign if_idx = if_pc_in[s_index + 2 - 1 : 2];
assign ex_idx = ex_pc_in[s_index + 2 - 1 : 2];

// check btb to predict
always_comb begin
    // default
    predicted_pc = '0;
    btb_flag = '0;

    if (btb[if_idx].br_pc == if_pc_in) begin    // if it is a br instr
        if (btb[if_idx].predict) begin// take br
            predicted_pc = btb[if_idx].target_pc;
            btb_flag = 2'b11;
        end
        else   // not take br
            btb_flag = 2'b10;
    end

end

// updating btb
always_ff @(posedge clk)
begin
    if (rst) begin
        for (int i = 0; i < num_sets; ++i)
            btb[i] <= '0;
    end
    else begin  // TODO
        if (update_btb) begin
            btb[ex_idx].br_pc <= ex_pc_in;
            btb[ex_idx].target_pc <= br_out;
        end
        if (update)
            btb[ex_idx].predict <= p_tnt;

    end
end

endmodule : btb_unit