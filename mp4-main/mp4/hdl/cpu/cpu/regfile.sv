
module regfile
(
    input clk,
    input rst,
    input load,
    input [31:0] in,
    input [4:0] src_a, src_b, dest,
    output logic [31:0] reg_a, reg_b
);

//logic [31:0] data [32] /* synthesis ramstyle = "logic" */ = '{default:'0};
logic [31:0] data [32];

logic [31:0] reg7;
logic [31:0] reg6;
logic [31:0] reg5;
logic [31:0] reg4;
logic [31:0] reg3;
logic [31:0] reg2;
logic [31:0] reg1;
logic [31:0] reg0;

assign reg7 = data[7];
assign reg6 = data[6];
assign reg5 = data[5];
assign reg4 = data[4];
assign reg3 = data[3];
assign reg2 = data[2];
assign reg1 = data[1];
assign reg0 = data[0];

always_ff @(posedge clk)
begin
    if (rst)
    begin
        for (int i=0; i<32; i=i+1) begin
            data[i] <= '0;
        end
    end
    else if (load && dest)
    begin
        data[dest] <= in;
    end
end

always_comb
begin
    if (load && dest && ((dest == src_a) || (dest == src_b))) begin 
        reg_a = (dest == src_a) ? in : data[src_a];
        reg_b = (dest == src_b) ? in : data[src_b];
    end 
    else begin
        reg_a = src_a ? data[src_a] : 0;
        reg_b = src_b ? data[src_b] : 0;
    end
end

endmodule : regfile
