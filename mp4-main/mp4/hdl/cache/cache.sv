/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module cache #(
    parameter s_offset = 5,
    parameter s_index  = 4,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index,
    parameter s_way    = 2
)
(
    input clk,
    input rst,

    /* CPU memory signals */
    input   logic [31:0]    mem_address, //
    output  logic [255:0]   mem_rdata,
    input   logic [255:0]   mem_wdata,
    input   logic           mem_read,
    input   logic           mem_write,
    input   logic [3:0]     mem_byte_enable,
    output  logic           mem_resp,

    /* Physical memory signals */
    output  logic [31:0]    pmem_address,
    input   logic [255:0]   pmem_rdata,
    output  logic [255:0]   pmem_wdata,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic           pmem_resp,

    // to eviction write buffer
    output  logic           idle
);

logic [255:0] mem_rdata256;
logic [255:0] mem_wdata256;
logic [31:0] mem_byte_enable256;

assign mem_rdata = mem_rdata256;
assign mem_wdata256 = mem_wdata;
assign mem_byte_enable256 = '1;

logic data_read;
logic data_write;
logic tag_read;
logic tag_write;
logic valid_read;
logic valid_write;
logic dirty_read;
logic dirty_write;
logic dirty_in;
logic lru_read;
logic lru_write;
logic valid_in;
logic load_way;
logic load_rdata;
logic evict;
waymux::waymux_sel_t waymux_sel;
logic load_datain;
wdatamux::wdatamux_sel_t wdatamux_sel;
pmemmux::pmemmux_sel_t pmemmux_sel;
write_enmux::write_enmux_sel_t write_en_sel;

logic miss;
logic dirty;

cache_control control(.*);

cache_datapath #(s_offset, s_index, s_tag, s_mask, s_line, num_sets, s_way)
                datapath(.*);

// bus_adapter bus_adapter
// (   
//     .*, 
//     .address(mem_address)
// );

endmodule : cache
