
module mp4
import rv32i_types::*;
(
    input clk,
    input rst,
	
	//Remove after CP1
    // input 					instr_mem_resp,
    // input rv32i_word 	instr_mem_rdata,
	// input 					data_mem_resp,
    // input rv32i_word 	data_mem_rdata, 
    // output logic 			instr_read,
	// output rv32i_word 	instr_mem_address,
    // output logic 			data_read,
    // output logic 			data_write,
    // output logic [3:0] 	data_mbe,
    // output rv32i_word 	data_mem_address,
    // output rv32i_word 	data_mem_wdata

	
	// For CP2
	 
    input pmem_resp,
    input [63:0] pmem_rdata,

	//To physical memory
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
	
);


//caches to datapath
logic 		instr_mem_resp;
rv32i_word 	instr_mem_rdata;
logic 	    data_mem_resp;
rv32i_word 	data_mem_rdata;

//datapath to caches
logic 		instr_read;
rv32i_word 	instr_mem_address;
logic 		data_read;
logic 		data_write;
logic [3:0] 	data_mbe;
rv32i_word 	data_mem_address;
rv32i_word 	data_mem_wdata;

//cache - arbiter
logic 	arb_instr_read;
rv32i_word 	arb_instr_mem_address;
logic 	arb_data_read;
logic 	arb_data_write;
logic [3:0] 	arb_data_mbe;
rv32i_word 	arb_data_mem_address;
logic [255:0]	arb_data_mem_wdata;
logic arb_instr_mem_resp;
logic [255:0] arb_instr_mem_rdata;
logic arb_data_mem_resp;
logic [255:0] arb_data_mem_rdata;





// Port to LLC (Lowest Level Cache)
logic [255:0] line_i;
logic [255:0] line_o;
logic [31:0] address_i;
logic read_i;
logic write_i;
logic resp_o;

// to l2 cache
rv32i_word l2_mem_addr;
logic [255:0] l2_rdata;
logic [255:0] l2_wdata;
logic l2_read;
logic l2_write;
logic l2_byte_enable;
logic l2_mem_resp;

rv32i_word l2_mem_addr_inst;
logic [255:0] l2_rdata_inst;
logic l2_read_inst;
logic l2_mem_resp_inst;

rv32i_word l2_mem_addr_data;
logic [255:0] l2_rdata_data;
logic [255:0] l2_wdata_data;
logic l2_read_data;
logic l2_write_data;
logic l2_byte_enable_data;
logic l2_mem_resp_data;

logic [255:0] eviction_wdata;
rv32i_word eviction_mem_address;
logic eviction_read;
logic eviction_write;
logic [255:0] eviction_rdata;
logic eviction_resp;

datapath d
(
   .*
);

given_cache instr_cache
(
   .clk(clk),
   .rst(rst),
   .pmem_resp(arb_instr_mem_resp),
   .pmem_rdata(arb_instr_mem_rdata),
   .pmem_address(arb_instr_mem_address),
   .pmem_wdata(),
   .pmem_read(arb_instr_read),
   .pmem_write(),

   .mem_read(instr_read),
   .mem_write(1'b0),
   .mem_byte_enable_cpu(4'b1111),
   .mem_address(instr_mem_address),
   .mem_wdata_cpu(32'b0),
   .mem_resp(instr_mem_resp),
   .mem_rdata_cpu(instr_mem_rdata)

);

given_cache data_cache
(
   .clk(clk),
   .rst(rst),
   .mem_resp(data_mem_resp),
   .mem_rdata_cpu(data_mem_rdata),
   .mem_read(data_read),
   .mem_write(data_write),
   .mem_byte_enable_cpu(data_mbe),
   .mem_address(data_mem_address),
   .mem_wdata_cpu(data_mem_wdata),

//    .pmem_wdata(eviction_wdata),
//    .pmem_address(eviction_mem_address),
//    .pmem_read(eviction_read),
//    .pmem_write(eviction_write),
//    .pmem_rdata(eviction_rdata),
//    .pmem_resp(eviction_resp)  
    .pmem_address(arb_data_mem_address),
    .pmem_rdata(arb_data_mem_rdata),
    .pmem_wdata(arb_data_mem_wdata),
    .pmem_read(arb_data_read),
    .pmem_write(arb_data_write),
    .pmem_resp(arb_data_mem_resp)
);


// eviction_buffer eviction_buffer(
//     .clk(clk),
//     .rst(rst),

//     .mem_address(eviction_mem_address), //
//     .mem_rdata(eviction_rdata),
//     .mem_wdata(eviction_wdata),
//     .mem_read(eviction_read),
//     .mem_write(eviction_write),
//     .mem_byte_enable('1),
//     .mem_resp(eviction_resp),

//     /* Physical memory signals */
//     .pmem_address(arb_data_mem_address),
//     .pmem_rdata(arb_data_mem_rdata),
//     .pmem_wdata(arb_data_mem_wdata),
//     .pmem_read(arb_data_read),
//     .pmem_write(arb_data_write),
//     .pmem_resp(arb_data_mem_resp)
// );



arbiter a
(
    .clk(clk),
    .rst(rst),
    .instr_read(arb_instr_read),
    .instr_mem_address(arb_instr_mem_address),
    .instr_mem_resp(arb_instr_mem_resp),
    .instr_mem_rdata(arb_instr_mem_rdata),

    // .instr_mem_address(l2_mem_addr_inst),
    // .instr_mem_rdata(l2_rdata_inst),
    // .instr_read(l2_read_inst),
    // .instr_mem_resp(l2_mem_resp_inst),

    .data_mem_resp(arb_data_mem_resp),
    .data_mem_rdata(arb_data_mem_rdata), 
    .data_read(arb_data_read),
    .data_write(arb_data_write),
    .data_mbe(arb_data_mbe),
    .data_mem_address(arb_data_mem_address),
    .data_mem_wdata(arb_data_mem_wdata),

    // .data_mem_address(l2_mem_addr_data),
    // .data_mem_rdata(l2_rdata_data),
    // .data_mem_wdata(l2_wdata_data),
    // .data_read(l2_read_data),
    // .data_write(l2_write_data),
    // .data_mem_resp(l2_mem_resp_data),
    // .data_mbe('1),

    .pmem_resp(l2_mem_resp),
    .pmem_rdata(l2_rdata),

    .pmem_read(l2_read),
    .pmem_write(l2_write),
    .pmem_address(l2_mem_addr),
    .pmem_wdata(l2_wdata)

    // .pmem_address(address_i),
    // .pmem_rdata(line_o),
    // .pmem_wdata(line_i),
    // .pmem_read(read_i),
    // .pmem_write(write_i),
    // .pmem_resp(resp_o)
);

// cache l2(
//     .clk(clk),
//     .rst(rst),
//     .mem_address(l2_mem_addr),
//     .mem_rdata(l2_rdata),
//     .mem_wdata(l2_wdata),
//     .mem_read(l2_read),
//     .mem_write(l2_write),
//     .mem_byte_enable(4'b1111),
//     .mem_resp(l2_mem_resp),

//     .pmem_address(eviction_mem_address),
//     .pmem_rdata(eviction_rdata),
//     .pmem_wdata(eviction_wdata),
//     .pmem_read(eviction_read),
//     .pmem_write(eviction_write),
//     .pmem_resp(eviction_resp),

//     .idle()
// );

cache l2(
    .clk(clk),
    .rst(rst),
    .mem_address(l2_mem_addr),
    .mem_rdata(l2_rdata),
    .mem_wdata(l2_wdata),
    .mem_read(l2_read),
    .mem_write(l2_write),
    .mem_byte_enable(4'b1111),
    .mem_resp(l2_mem_resp),

    .pmem_address(address_i),
    .pmem_rdata(line_o),
    .pmem_wdata(line_i),
    .pmem_read(read_i),
    .pmem_write(write_i),
    .pmem_resp(resp_o),

    .idle()
);


// eviction_buffer eviction_buffer(
//     .clk(clk),
//     .rst(rst),

//     .mem_address(eviction_mem_address), //
//     .mem_rdata(eviction_rdata),
//     .mem_wdata(eviction_wdata),
//     .mem_read(eviction_read),
//     .mem_write(eviction_write),
//     .mem_byte_enable('1),
//     .mem_resp(eviction_resp),

//     /* Physical memory signals */
//     .pmem_address(address_i),
//     .pmem_rdata(line_o),
//     .pmem_wdata(line_i),
//     .pmem_read(read_i),
//     .pmem_write(write_i),
//     .pmem_resp(resp_o)
// );


given_cacheline_adaptor cacheline_adaptor
(
    .clk(clk),
    .reset_n(~rst),
   // Port to LLC (Lowest Level Cache)
   .line_i(line_i),
   .line_o(line_o),
   .address_i(address_i),
   .read_i(read_i),
   .write_i(write_i),
   .resp_o(resp_o),

// Port to memory
   .burst_i(pmem_rdata),
   .burst_o(pmem_wdata),
   .address_o(pmem_address),
   .read_o(pmem_read),
   .write_o(pmem_write),
   .resp_i(pmem_resp)
);


endmodule : mp4
