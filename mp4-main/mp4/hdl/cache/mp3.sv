module mp3
import rv32i_types::*;
(
    input clk,
    input rst,
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);

logic [31:0]    mem_address;
logic [31:0]    mem_rdata;
logic [31:0]    mem_wdata;
logic           mem_read;
logic           mem_write;
logic [3:0]     mem_byte_enable;
logic           mem_resp;

logic [31:0]    address_i;
logic [255:0]   line_o, line_i;
logic           read_i, write_i, resp_o;

// Keep cpu named `cpu` for RVFI Monitor
// Note: you have to rename your mp2 module to `cpu`
cpu cpu(.*);

// Keep cache named `cache` for RVFI Monitor
cache cache(
    .*, 
    .pmem_address(address_i),
    .pmem_rdata(line_o),
    .pmem_wdata(line_i),
    .pmem_read(read_i),
    .pmem_write(write_i),
    .pmem_resp(resp_o)
);

// Hint: What do you need to interface between cache and main memory?
cacheline_adaptor cacheline_adaptor
(
    .clk(clk),
    .reset_n(~rst),

    // Port to LLC (Lowest Level Cache)
    .*,

    // Port to memory
    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_address),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
);

endmodule : mp3