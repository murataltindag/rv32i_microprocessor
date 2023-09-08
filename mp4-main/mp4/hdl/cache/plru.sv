
module plru #(
    parameter s_index = 3,
    parameter s_way    = 1
)
(
    clk,
    rst,
    hit,
    evict,
    read,
    set,
    way,
    lru
);

localparam num_sets = 2**s_index;
localparam num_way = 2**s_way;

input clk;
input rst;
input [(num_way-1):0] hit;
input evict;
input read;
input [s_index-1:0] set;
input [s_way-1:0] way;
output logic [s_way-1:0] lru;

logic [(num_sets-1):0][(num_way-1):0] mru;

// hits/bringing value forward sets mru[set][way] to 1
// 0 out rest of elements when all values 1 to prevent deadlock

always_ff @(posedge clk)
begin
    if (rst) begin
        lru <= '0;
        for (int i = 0; i < num_sets; ++i) 
            mru[i] <= '0;
    end
    else begin
        if (hit != '0) begin  // set high on hit
            mru[set][way] <= 1;
        end 
    end

    if (mru[set] == '1) begin  // 0 out rest of elements when all high
        mru[set] <= '0;
        mru[set][way] <= 1;
    end

    if (read) begin
        for (int i = 0; i < num_way; i++) begin 
            if (mru[set][i] == '0) begin 
                lru <= i;
                break;
            end
        end
    end
end

endmodule : plru
