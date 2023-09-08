/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control (
    input clk,
    input rst,
    // cpu to control
    input logic mem_read,
    input logic mem_write,

    // datapath to control
    input logic miss,
    input logic dirty,

    // memory to control
    input logic pmem_resp,

    // control to datapath
    output logic data_read,
    output logic data_write,
    output logic tag_read,
    output logic tag_write,
    output logic valid_read,
    output logic valid_write,
    output logic dirty_read,
    output logic dirty_write,
    output logic dirty_in,
    output logic lru_read,
    output logic lru_write,
    output logic valid_in,

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

enum int unsigned {
    /* List of states */
    CHECK_TAG, 
    RW,
    UPDATE_CACHE,
    MEM,
    WRITEBACK
} state, next_state;

/************************* Function Definitions *******************************/
function void set_defaults();
    data_read = 1'b1; // there's a mux anyway - remove if unnecessary
    data_write = 1'b0;
    tag_read = 1'b1;
    tag_write = 1'b0;
    valid_read = 1'b1;
    valid_write = 1'b0;
    dirty_read = 1'b0;
    dirty_write = 1'b0;
    lru_read = 1'b1;
    lru_write = 1'b0;
    valid_in = 1'b0;
    dirty_in = 1'b0;

    load_way = 1'b0;
    load_datain = 1'b0;
    mem_resp = 1'b0;
    pmem_read = 1'b0;
    pmem_write = 1'b0;
    load_rdata = 1'b0;

    write_en_sel = write_enmux::cpu;
endfunction

function void readData(); 
    data_read = 1'b1; // read data from cache
    load_rdata = 1'b1;
    lru_write = 1'b1; // update LRU to ~way
    mem_resp = 1'b1; // assert mem_resp
endfunction

function void writeData(wdatamux::wdatamux_sel_t sel); 
    data_write = 1'b1; // write data to cache
    load_datain = 1'b1;
    write_en_sel = write_enmux::cpu;
    wdatamux_sel = sel; 
    dirty_write = 1'b1; // mark data dirty
    dirty_in = 1'b1;
    lru_write = 1'b1; // update LRU to ~way
    mem_resp = 1'b1; // assert mem_resp
endfunction

function void check_tag(); 
    tag_read = 1'b1; // read tag + valid
    data_read = 1'b1;
    valid_read = 1'b1;
    load_way = 1'b1; // update way
    waymux_sel = waymux::cmp;
endfunction

function void rw(); 
    if (mem_read & ~miss) 
        readData();
    else if (mem_write & ~miss) 
        writeData(wdatamux::wdata);
endfunction

function void mem(); 
    pmem_read = 1'b1; // read mem_address from memory
    pmemmux_sel = pmemmux::mem_address;
    dirty_read = 1'b1;
    wdatamux_sel = wdatamux::line_o;
    load_datain = 1'b1;
    load_way = 1'b1;
    waymux_sel = waymux::lru;

    if (pmem_resp) begin 
        valid_write = 1'b1;
        // valid_read = 1'b1;
        valid_in = 1'b1;
    end
endfunction

function void writeback(); 
    pmem_write = 1'b1; // write to tag address from memory
    pmemmux_sel = pmemmux::tag;
    data_read = 1'b1;
    lru_read = 1'b1;
    // waymux_sel = waymux::lru;
    // load_way = 1'b1;
endfunction

function void update_cache(); 
    tag_write = 1'b1; // add new entry to cache
    valid_write = 1'b1;
    valid_read = 1'b1;
    valid_in = 1'b1;
    data_write = 1'b1;
    write_en_sel = write_enmux::line;
    dirty_write = 1'b1;
    dirty_in = 1'b0;
    // lru_write = 1'b1;

    waymux_sel = waymux::lru;
    load_way = 1'b1;


    data_read = 1'b1;
    tag_read = 1'b1; // read tag + valid
    valid_read = 1'b1;
endfunction

/*****************************************************************************/

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
    unique case (state)
        CHECK_TAG: check_tag();
        RW: rw();
        MEM: mem();
        WRITEBACK: writeback();
        UPDATE_CACHE: update_cache();
    endcase
end

always_comb
begin : next_state_logic
    case(state)
        CHECK_TAG: begin 
            if (~(mem_read | mem_write)) 
                next_state = CHECK_TAG;
            else if (~miss) 
                next_state = RW;
            else if (miss) 
                next_state = MEM; 
        end

        RW: next_state = CHECK_TAG;

        MEM: begin 
            if (~pmem_resp) 
                next_state = MEM;
            else if (dirty)
                next_state = WRITEBACK;
            else if (~dirty) 
                next_state = UPDATE_CACHE;
        end

        WRITEBACK: begin 
            if (~pmem_resp) 
                next_state = WRITEBACK;
            else
                next_state = UPDATE_CACHE;
        end

        UPDATE_CACHE: next_state = RW;
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    if (rst == 1'b1) // rst signal
        state <= CHECK_TAG;
    else 
        state <= next_state;
end

endmodule : cache_control
