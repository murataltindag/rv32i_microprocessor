/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module eviction_control (
    input clk,
    input rst,
    // cpu to control
    input logic mem_read,
    input logic mem_write,

    // datapath to control
    input logic miss,
    // input logic dirty,
    input logic full, 
    input logic empty,

    // memory to control
    input logic pmem_resp,

    // control to datapath
    output logic data_read,
    output logic data_write,
    output logic tag_read,
    output logic tag_write,
    output logic valid_read,
    output logic valid_write,
    // output logic dirty_read,
    // output logic dirty_write,
    // output logic dirty_in,
    output logic lru_read,
    output logic lru_write,
    output logic valid_in,
    output logic evict,
    output logic forward,

    output logic load_way,
    output waymux::waymux_sel_t waymux_sel,
    output logic load_datain,
    output wdatamux::wdatamux_sel_t wdatamux_sel,
    output pmemmux::pmemmux_sel_t pmemmux_sel,
    output write_enmux::write_enmux_sel_t write_en_sel,
    output logic load_rdata,
    // control to cpu
    output logic mem_resp,

    // control to memory
    output logic pmem_read,
    output logic pmem_write
);

logic [1:0] counter;

enum int unsigned {
    /* List of states */
    CHECK_TAG, 
    RW,
    UPDATE_CACHE,
    // MEM,
    WRITEBACK,
    FW
} state, next_state;

/************************* Function Definitions *******************************/
function void set_defaults();
    data_read = 1'b1; // there's a mux anyway - remove if unnecessary
    data_write = 1'b0;
    tag_read = 1'b1;
    tag_write = 1'b0;
    valid_read = 1'b1;
    valid_write = 1'b0;
    // dirty_read = 1'b0;
    // dirty_write = 1'b0;
    lru_read = 1'b1;
    lru_write = 1'b0;
    valid_in = 1'b0;
    // dirty_in = 1'b0;
    evict = 1'b0;

    load_way = 1'b0;
    load_datain = 1'b0;
    mem_resp = 1'b0;
    pmem_read = 1'b0;
    pmem_write = 1'b0;
    load_rdata = 1'b0;

    write_en_sel = write_enmux::cpu;
    waymux_sel = waymux::cmp;

    forward = '0;
endfunction

function void readData(); 
    data_read = 1'b1; // read data from cache
    load_rdata = 1'b1;
    lru_write = 1'b1; // update LRU to ~way
    mem_resp = 1'b1; // assert mem_resp
endfunction

// function void writeData(wdatamux::wdatamux_sel_t sel); 
//     data_write = 1'b1; // write data to cache
//     load_datain = 1'b1;
//     write_en_sel = write_enmux::cpu;
//     wdatamux_sel = sel; 
//     lru_write = 1'b1; // update LRU to ~way
//     mem_resp = 1'b1; // assert mem_resp
// endfunction

function void check_tag(); 
    tag_read = 1'b1; // read tag + valid
    data_read = 1'b1;
    valid_read = 1'b1;
    load_way = 1'b1; // update way
    waymux_sel = waymux::cmp;
    lru_write = 1'b1;
endfunction

function void rw(); 
    if (mem_read & ~miss) 
        readData();
    // else if (mem_write & ~miss) 
    //     writeData(wdatamux::wdata);
endfunction

function void writeback(); 
    pmem_write = 1'b1; // write to tag address from memory
    pmemmux_sel = pmemmux::tag;
    data_read = 1'b1;
    lru_read = 1'b1;
    waymux_sel = waymux::mru;
    valid_write = 1'b1;
    valid_in = 1'b0;
endfunction

function void update_cache(); 
    tag_write = 1'b1; // add new entry to cache
    valid_write = 1'b1;
    valid_read = 1'b1;
    valid_in = 1'b1;
    data_write = 1'b1;
    write_en_sel = write_enmux::line;
    wdatamux_sel = wdatamux::wdata;
    evict = 1'b1;

    waymux_sel = waymux::lru;
    load_way = 1'b1;

    data_read = 1'b1;
    tag_read = 1'b1; // read tag + valid
    valid_read = 1'b1;
    mem_resp = 1'b1;
endfunction

function void fw();
    forward = 1'b1;
    pmem_read = mem_read;
    pmem_write = mem_write;
    mem_resp = pmem_resp;
endfunction

/*****************************************************************************/

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
    case (state)
        CHECK_TAG: check_tag();
        RW: rw();
        WRITEBACK: writeback();
        UPDATE_CACHE: update_cache();
        FW: fw();
    endcase
end

always_comb
begin : next_state_logic
    case(state)
        CHECK_TAG: begin 
            if (~(mem_read | mem_write) & ~empty & (counter == '1)) 
                next_state = WRITEBACK;
            else if ((mem_read & ~miss)) 
                next_state = RW;
            else if ((mem_write & miss & ~full))
                next_state = UPDATE_CACHE;
            else if (mem_read | mem_write) 
                next_state = FW; 
            else 
                next_state = CHECK_TAG;
        end

        RW: next_state = CHECK_TAG;

        // MEM: begin 
        //     if (~pmem_resp) 
        //         next_state = MEM;
        //     else 
        //         next_state = UPDATE_CACHE;
        // end

        WRITEBACK: begin 
            if (~pmem_resp) 
                next_state = WRITEBACK;
            else
                next_state = CHECK_TAG;
        end

        FW: begin 
            if (~pmem_resp) 
                next_state = FW;
            else
                next_state = CHECK_TAG;
        end

        UPDATE_CACHE: next_state = CHECK_TAG;
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    if (rst == 1'b1) begin // rst signal
        state <= CHECK_TAG;
        counter <= '0;
    end
    else begin 
        if (state == UPDATE_CACHE)
            counter <= '0;
        else if (counter != '1) 
            counter <= counter + 1'b1;
        state <= next_state;
    end
end

endmodule : eviction_control
