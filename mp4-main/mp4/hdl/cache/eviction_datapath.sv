/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module eviction_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index,
    parameter s_way    = 1
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
    // input logic dirty_read,
    // input logic dirty_write,
    // input logic dirty_in,
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
    input logic evict,
    input logic forward,

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
    output logic full,
    output logic empty,
    // output logic dirty,

    // datapath to memory
    output logic [31:0] pmem_address,
    output logic [255:0] pmem_wdata,
    
    // datapath to cpu
    output logic [255:0] mem_rdata256
);

localparam tag_idx_h = 31;
localparam tag_idx_l = (32 - s_tag);
localparam set_idx_h = (s_index) ? (32 - s_tag - 1) : 0;
localparam set_idx_l = (s_index) ? s_offset : 0;
localparam offset_idx_h = s_offset - 1;
localparam offset_idx_l = 0;
localparam num_way = 2**s_way;

localparam block_bytes = 2**s_offset;
localparam block_bits = 8*block_bytes;

logic [tag_idx_h:tag_idx_l] tag;
logic [set_idx_h:set_idx_l] set;
logic [offset_idx_h:offset_idx_l] offset;
logic [(s_way - 1): 0] way;

assign tag = mem_address[tag_idx_h:tag_idx_l];
assign set = (s_index) ? mem_address[(set_idx_h + (set_idx_h == 0)):set_idx_l] : '0;
assign offset = mem_address[offset_idx_h:offset_idx_l];

logic [(num_way - 1): 0][(block_bits - 1):0] dataout; // data array
logic [(num_way - 1): 0][(s_tag - 1):0] tag_out; 
logic [(num_way - 1): 0] valid_out; 
// logic [(num_way - 1): 0] dirty_out; 
logic [(s_way - 1)  : 0] lru_out; 
logic [(s_way - 1)  : 0] mru_out; 

logic [(block_bits - 1):0] datain;
logic [(block_bits - 1):0] data;
logic [(block_bytes - 1):0] data_write_en;
logic [(num_way-1):0] hit;

// logic [1:0] valid_array[7:0];

genvar i; // generate iterator
generate

    for( i = 0 ; i < num_way; i++) begin: array_generation
        // data arrays 
        data_array #(s_offset, s_index) data_array(
            .clk(clk),
            .read(data_read),
            .write_en(data_write_en & {32{(way == s_way'(i))}}),
            .rindex('0),
            .windex('0),
            .datain(datain),
            .dataout(dataout[i])
        );

        valid_array #(s_index, s_tag) tag_array(
            .clk(clk),
            .rst(rst),
            .load(tag_write & (way == s_way'(i))),
            .rindex('0),
            .windex('0),
            .datain(tag),
            .dataout(tag_out[i])
        );

        // valid arrays
        valid_array #(s_index, 1) valid_array(
            .clk(clk),
            .rst(rst),
            .load(valid_write & (way == s_way'(i))),
            .rindex('0),
            .windex('0),
            .datain(valid_in),
            .dataout(valid_out[i])
        );

        // dirty arrays 
        // array #(s_index, 1) dirty_array(
        //     .clk(clk),
        //     .rst(rst),
        //     .read(dirty_read),
        //     .load(dirty_write & (way == s_way'(i))),
        //     .rindex(set),
        //     .windex(set),
        //     .datain(dirty_in),
        //     .dataout(dirty_out[i])
        // );
    end
endgenerate

// mru-based pseudo-lru replacement (https://people.kth.se/~ingo/MasterThesis/ThesisDamienGille2007.pdf)
plru #(s_index, s_way) plru(
    .clk(clk),
    .rst(rst),
    .hit(hit),
    .evict(evict),
    .set('0),
    .read(lru_write),
    .way(way),
    .lru(lru_out)
);

// MUXES AND COMPARATORS
always_comb begin : MUXES
    if (forward) begin 
        pmem_address = mem_address;
        mem_rdata256 = pmem_rdata;
        pmem_wdata = mem_wdata256;
    end
    else begin 
        // select outputs of arrays based on way
        mem_rdata256 = (~miss & load_rdata) ? dataout[way] : 256'hx;
        pmem_wdata = dataout[way];
        // dirty = dirty_out[way];
        datain = mem_wdata256;

        // write data
        // if (load_datain) begin 
        // unique case (wdatamux_sel)
        //     wdatamux::wdata: 
        //     wdatamux::line_o: datain = pmem_rdata;
        // endcase
        // end

        // pmem address
        unique case (pmemmux_sel)
            pmemmux::mem_address: pmem_address = mem_address;
            pmemmux::tag: pmem_address = {tag_out[way], 5'b0}; // should this be zero'd out
            default: ;
        endcase
    end
    // full/empty 
    full = (valid_out == '1) ? '1 : '0;
    empty = (valid_out == '0) ? '1 : '0;
    // set miss
    for (int i = 0; i < num_way; ++i) begin 
        hit[i] = (valid_out[i] & (tag_out[i] == tag));
    end
    miss = (hit == '0) ? '1 : '0; // high if no hits
    
    // mru_out 
    for (int i = 0; i < num_way; ++i) begin 
        if (valid_out[i] == '1) begin 
            mru_out = i;
            break;
        end
    end

    // set way
    // if (load_way) begin 
    unique case (waymux_sel)
        waymux::cmp: begin 
            for (int i = 0; i < num_way; i++) begin 
                if (hit[i] == '1) begin 
                    way = i;
                    break;
                end
            end
        end
        waymux::lru: way = lru_out;
        waymux::mru: way = mru_out;
        default: ;
    endcase

    // write enable
    unique case (write_en_sel) 
        write_enmux::cpu: data_write_en = mem_byte_enable256 & {32{data_write}};
        write_enmux::line: data_write_en = {32{data_write}};
        default: ;
    endcase
end

endmodule : eviction_datapath