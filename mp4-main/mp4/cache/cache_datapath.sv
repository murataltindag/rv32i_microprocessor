/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index,
    parameter s_way  = 1
)
(
    input clk,
    input rst,

    // control to datapath
    input logic data_read,
    input logic data_write,
    input logic tag_read,
    input logic tag_write,
    input logic valid_read,
    input logic valid_write,
    input logic dirty_read,
    input logic dirty_write,
    input logic dirty_in,
    input logic lru_read,
    input logic lru_write,
    input logic valid_in,
    input logic load_way,
    input waymux::waymux_sel_t waymux_sel,
    input logic load_datain,
    input wdatamux::wdatamux_sel_t wdatamux_sel,
    input pmemmux::pmemmux_sel_t pmemmux_sel,
    input write_enmux::write_enmux_sel_t write_en_sel,
    input logic load_rdata,

    // cpu to datapath
    input logic [31:0] mem_byte_enable256,
    input logic [31:0] mem_address,
    input logic [255:0] mem_wdata256,
    // input logic mem_read,
    // input logic mem_write,

    // memory to datapath
    input logic [255:0] pmem_rdata,

    // datapath to control
    output logic miss,
    output logic dirty,

    // datapath to memory
    output logic [31:0] pmem_address,
    output logic [255:0] pmem_wdata,
    
    // datapath to cpu
    output logic [255:0] mem_rdata256
);

localparam tag_idx_h = 31;
localparam tag_idx_l = (32 - s_tag);
localparam set_idx_h = (32 - s_tag - 1);
localparam set_idx_l = s_offset;
localparam offset_idx_h = s_offset - 1;
localparam offset_idx_l = 0;
localparam num_way = 2**s_way;

logic [tag_idx_h:tag_idx_l] tag;
logic [set_idx_h:set_idx_l] set;
logic [offset_idx_h:offset_idx_l] offset;
logic [(s_way - 1): 0] way;

assign tag = mem_address[tag_idx_h:tag_idx_l];
assign set = mem_address[set_idx_h:set_idx_l];
assign offset = mem_address[offset_idx_h:offset_idx_l];

logic [(num_way - 1): 0][255:0] dataout; // data array
logic [(num_way - 1): 0][23:0] tag_out; 
logic [(num_way - 1): 0] valid_out; 
logic [(num_way - 1): 0] dirty_out; 
logic [(s_way - 1)  : 0] lru_out; 

logic [255:0] datain;
logic [255:0] data;
logic [31:0] data_write_en;
// logic [1:0] valid_array[7:0];

genvar i; // generate iterator
generate
    for( i = 0 ; i < num_way; i++) begin: array_generation
        // data arrays 
        data_array #(s_offset, s_index) data_array(
            .clk(clk),
            .read(data_read),
            .write_en(data_write_en & {32{(way == s_way'(i))}}),
            .rindex(set),
            .windex(set),
            .datain(datain),
            .dataout(dataout[i])
        );

        // tag arrays
        array #(3, 24) tag_array(
            .clk(clk),
            .rst(rst),
            .read(tag_read),
            .load(tag_write & (way == s_way'(i))),
            .rindex(set),
            .windex(set),
            .datain(tag),
            .dataout(tag_out[i])
        );

        valid_array #(3, 24) tag_array(
            .clk(clk),
            .rst(rst),
            .load(tag_write & (way == s_way'(i))),
            .rindex(set),
            .windex(set),
            .datain(tag),
            .dataout(tag_out[i])
        );

        // valid arrays
        // array #(3, 1) valid_array(
        //     .clk(clk),
        //     .rst(rst),
        //     .read(valid_read),
        //     .load(valid_write  & (way == 1'(i))),
        //     .rindex(set),
        //     .windex(set),
        //     .datain(valid_in),
        //     .dataout(valid_out[i])
        // );

        valid_array #(3, 1) valid_array(
            .clk(clk),
            .rst(rst),
            .load(valid_write  & (way == s_way'(i))),
            .rindex(set),
            .windex(set),
            .datain(valid_in),
            .dataout(valid_out[i])
        );

        // dirty arrays 
        array #(3, 1) dirty_array(
            .clk(clk),
            .rst(rst),
            .read(dirty_read),
            .load(dirty_write & (way == s_way'(i))),
            .rindex(set),
            .windex(set),
            .datain(dirty_in),
            .dataout(dirty_out[i])
        );
    end
endgenerate

// lru array 
array #(3, 1) lru_array(
    .clk(clk),
    .rst(rst),
    .read(lru_read),
    .load(lru_write),
    .rindex(set),
    .windex(set),
    .datain(~way),
    .dataout(lru_out)
);

// MUXES AND COMPARATORS
always_comb begin : MUXES

    // select outputs of arrays based on way
    mem_rdata256 = (~miss & load_rdata) ? dataout[way] : 256'hx;
    pmem_wdata = dataout[way];
    dirty = dirty_out[way];

    // set miss
    miss = ~((valid_out[0] & (tag_out[0] == tag)) | (valid_out[1] & (tag_out[1] == tag)));
    // set way
    if (load_way) begin 
    unique case (waymux_sel)
        waymux::cmp: way = (valid_out[1] & (tag_out[1] == tag)) ? 1'b1 : 1'b0; // if not miss
        waymux::lru: way = lru_out;
    endcase
    end

    // write enable
    unique case (write_en_sel) 
        write_enmux::cpu: data_write_en = mem_byte_enable256 & {32{data_write}};
        write_enmux::line: data_write_en = {32{data_write}};
    endcase

    // write data
    if (load_datain) begin 
    unique case (wdatamux_sel)
        wdatamux::wdata: datain = mem_wdata256;
        wdatamux::line_o: datain = pmem_rdata;
    endcase
    end

    // pmem address
    unique case (pmemmux_sel)
        pmemmux::mem_address: pmem_address = mem_address;
        pmemmux::tag: pmem_address = {tag_out[way], set, 5'b0}; // should this be zero'd out
    endcase
end

endmodule : cache_datapath
