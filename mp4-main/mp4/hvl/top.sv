module mp4_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// Dump signals
initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, mp4_tb, "+all");
end
/****************************** End do not touch *****************************/


/************************ Signals necessary for monitor **********************/
// This section not required until CP2

// assign rvfi.commit = ((dut.d.write_back.cw_o.load_pc) | dut.d.write_back.cw_o.load_regfile) & ~(dut.d.if_stall |dut.d.decode_stall |dut.d.mem_stall) & dut.d.load_pc; // Set high when a valid instruction is modifying regfile or PC
assign rvfi.commit = 0; // Set high when a valid instruction is modifying regfile or PC
// assign rvfi.halt = ((dut.d.write_back.cw_o.monitor_info.pc_rdata == dut.d.write_back.cw_o.monitor_info.pc_wdata) & dut.d.load_pc & (dut.d.write_back.cw_o.opcode == rv32i_types::op_br | dut.d.write_back.cw_o.opcode == rv32i_types::op_jalr)) ? 1 : 0; // Set high when target PC == Current PC for a branch
// assign rvfi.halt = (((dut.d.write_back.cw_o.monitor_info.pc_rdata == dut.d.write_back.cw_o.monitor_info.pc_wdata) & (dut.d.write_back.cw_o.opcode == rv32i_types::op_br)) & dut.d.load_pc) ? 1 : 0; // Set high when target PC == Current PC for a branch
assign rvfi.halt = ((((dut.d.write_back.cw_o.monitor_info.pc_rdata == dut.d.write_back.cw_o.monitor_info.pc_wdata) & (dut.d.write_back.cw_o.opcode == rv32i_types::op_br)) & dut.d.load_pc) | (dut.d.write_back.cw_o.monitor_info.inst == 32'h6f)) ? 1 : 0; // Set high when target PC == Current PC for a branch
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

/*
Instruction and trap:
    rvfi.inst
    rvfi.trap

Regfile:
    rvfi.rs1_addr
    rvfi.rs2_add
    rvfi.rs1_rdata
    rvfi.rs2_rdata
    rvfi.load_regfile
    rvfi.rd_addr
    rvfi.rd_wdata

PC:
    rvfi.pc_rdata
    rvfi.pc_wdata

Memory:
    rvfi.mem_addr
    rvfi.mem_rmask
    rvfi.mem_wmask
    rvfi.mem_rdata
    rvfi.mem_wdata

Please refer to rvfi_itf.sv for more information.
*/

// Instruction and trap:
assign rvfi.inst = dut.d.write_back.cw_o.monitor_info.inst;
assign rvfi.trap = '0;

// Regfile:
assign rvfi.rs1_addr = dut.d.write_back.cw_o.monitor_info.rs1_addr;
assign rvfi.rs2_addr = dut.d.write_back.cw_o.monitor_info.rs2_addr;
assign rvfi.rs1_rdata = dut.d.write_back.cw_o.monitor_info.rs1_rdata;
assign rvfi.rs2_rdata = dut.d.write_back.cw_o.monitor_info.rs2_rdata;
assign rvfi.load_regfile = dut.d.write_back.cw_o.load_regfile;
assign rvfi.rd_addr = dut.d.write_back.cw_o.rd;
assign rvfi.rd_wdata = dut.d.write_back.cw_o.monitor_info.rd_wdata;

// PC:
assign rvfi.pc_rdata = dut.d.write_back.cw_o.monitor_info.pc_rdata;
assign rvfi.pc_wdata = dut.d.write_back.cw_o.monitor_info.pc_wdata;

//Memory:
assign rvfi.mem_addr = dut.d.write_back.cw_o.monitor_info.mem_addr;
assign rvfi.mem_rmask = dut.d.write_back.cw_o.monitor_info.mem_rmask;
assign rvfi.mem_wmask = dut.d.write_back.cw_o.monitor_info.mem_wmask;
assign rvfi.mem_rdata = dut.d.write_back.cw_o.monitor_info.mem_rdata;
assign rvfi.mem_wdata = dut.d.write_back.cw_o.monitor_info.mem_wdata;

/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*
The following signals need to be set:
icache signals:
    itf.inst_read
    itf.inst_addr
    itf.inst_resp
    itf.inst_rdata

dcache signals:
    itf.data_read
    itf.data_write
    itf.data_mbe
    itf.data_addr
    itf.data_wdata
    itf.data_resp
    itf.data_rdata

Please refer to tb_itf.sv for more information.
*/

assign itf.inst_read = dut.instr_read;
assign itf.inst_addr = dut.instr_mem_address;
assign itf.inst_resp = dut.instr_mem_resp;
assign itf.inst_rdata = dut.instr_mem_rdata;

assign itf.data_read = dut.data_read;
assign itf.data_write = dut.data_write;
assign itf.data_mbe = dut.data_mbe;
assign itf.data_addr = dut.data_mem_address;
assign itf.data_wdata = dut.data_mem_wdata;
assign itf.data_resp = dut.data_mem_resp;
assign itf.data_rdata = dut.data_mem_rdata;

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = '{default: '0};

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level for CP2:
Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/

mp4 dut(
    .clk(itf.clk),
    .rst(itf.rst),
    
     // Remove after CP1
    // .instr_mem_resp(itf.inst_resp),
    // .instr_mem_rdata(itf.inst_rdata),
	// .data_mem_resp(itf.data_resp),
    // .data_mem_rdata(itf.data_rdata),
    // .instr_read(itf.inst_read),
	// .instr_mem_address(itf.inst_addr),
    // .data_read(itf.data_read),
    // .data_write(itf.data_write),
    // .data_mbe(itf.data_mbe),
    // .data_mem_address(itf.data_addr),
    // .data_mem_wdata(itf.data_wdata)


    // Use for CP2 onwards
    .pmem_read(itf.mem_read),
    .pmem_write(itf.mem_write),
    .pmem_wdata(itf.mem_wdata),
    .pmem_rdata(itf.mem_rdata),
    .pmem_address(itf.mem_addr),
    .pmem_resp(itf.mem_resp)
    
);
/***************************** End Instantiation *****************************/

/***************************** Performance Counter ***************************/
int l2_tot = 0;
int l2_miss = 0;
always @(dut.l2.control.state == 3'b011) begin // on memory access
    l2_miss <= l2_miss + 1;
    @(dut.l2.control.state);
end

always @(dut.l2.control.state == 3'b1) begin // update_cache
    l2_tot <= l2_tot + 1;
    @(dut.l2.control.state);
end

// 
int evb_tot = 0;
int evb_write = 0;
int evb_read_hit = 0;

// always @(dut.eviction_buffer.control.state == 3'b0) begin // on check_tag
//     evb_tot <= evb_tot + 1;
//     @(dut.eviction_buffer.control.state);
// end

// always @(dut.eviction_buffer.control.state == 3'b1) begin // on rw
//     evb_read_hit <= evb_read_hit + 1;
//     @(dut.eviction_buffer.control.state);
// end

// always @(dut.eviction_buffer.control.state == 3'b10) begin // on rw
//     evb_write <= evb_write + 1;
//     @(dut.eviction_buffer.control.state);
// end

always @(posedge itf.clk) begin 
    if (rvfi.halt) begin 
        $display("L2 CACHE MISS RATE: %d / %d", l2_miss, l2_tot);
        $display("Register Values");
        for (int i = 0; i < 32; i++) begin 
            $display("%d: %x", i, dut.d.decode.regfile.data[i]);
        end
        // $display("EVICTION WRITE BUFFER STATS: %d read hits, %d writebacks, %d total accesses\n", evb_read_hit, evb_write, evb_tot);
        $finish;
    end
end
// logic [7:0][31:0] info;
// always @(dut.instr_cache.datapath.DM_cache.data) begin 
//     info[dut.instr_cache.datapath.DM_cache.windex] <= dut.instr_cache.datapath.mem_address;
//     $display("%d - Address %x: %x\n", dut.instr_cache.datapath.index, dut.instr_cache.datapath.mem_address + 32'ha0, dut.instr_cache.datapath.DM_cache.data[dut.instr_cache.datapath.DM_cache.windex]);
// end

// print all stores
// always @(negedge itf.clk && dut.data_write) begin
//     // ##1;
//     $display("%0t: M[0x%x] = %x @ pc = %x", $time, dut.data_mem_address, dut.data_mem_wdata, dut.d.memory.pc_out_i);
//     @(dut.data_write);
// end

// always @(negedge itf.clk && (dut.eviction_buffer.mem_address == 32'h109c)) begin
//     // ##1;
//     for (int i = 0; i < 4; i++) begin 
//         $display("%0t: M[0x%x] = 0x%x", $time, dut.eviction_buffer.datapath.array_generation[i].data_array.test_addr, dut.eviction_buffer.datapath.array_generation[i].data_array.data[0]);
//     end
//     @(dut.eviction_buffer.mem_address);
// end

// always @(dut.d.memory.pc_out_i) begin 
//     if (dut.d.memory.pc_out_i == 32'hd4c) begin
//         @(dut.data_mem_resp);
//         $display("%0t Write %x at memory location %x for pc 0xd4c\n", $time, dut.data_mem_wdata, dut.data_mem_address ); 
//         @(dut.d.memory.pc_out_i);
//     end
// end

// // print all stores
// always @(negedge itf.clk && dut.data_write) begin
//     // ##1;
//     $display("%0t: M[0x%x] = %x @ pc = %x", $time, dut.data_mem_address, dut.data_mem_wdata, dut.d.memory.pc_out_i);
//     @(dut.data_write);
// end

// int regfile_counter = 0;
// int instructions = 100000;
// always @(dut.d.decode.cw_i) begin 
//     if ((dut.d.decode.regfile.load == '1) & dut.d.decode.regfile.dest != '0) begin 
//         // if (regfile_counter < instructions) begin 
//             $display("%0t: R[%x] = %x", $time, dut.d.decode.regfile.dest, dut.d.decode.regfile.in);
//         // end
//         regfile_counter <= regfile_counter + 1;
//         if (regfile_counter > instructions) begin 
//             $finish;
//         end
//     end
// end

// every instr l2 read
// check rdata & address associated
// always @(negedge itf.clk && dut.eviction_write) begin 
//     $display("%0t: I$[%x] = %x @ address %x", $time, dut.eviction_buffer.datapath.way, dut.eviction_wdata, dut.eviction_mem_address);
// end

/***************************** End Performance Counter ***********************/
endmodule
