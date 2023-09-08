package wdatamux;
typedef enum bit {
    wdata  = 1'b0
    ,line_o  = 1'b1
} wdatamux_sel_t;
endpackage

package waymux;
typedef enum bit [1:0] {
    cmp = 2'b00
    ,lru = 2'b01
    ,mru = 2'b10
} waymux_sel_t;
endpackage

package pmemmux;
typedef enum bit {
    mem_address = 1'b0
    ,tag = 1'b1
} pmemmux_sel_t;
endpackage

package write_enmux;
typedef enum bit {
    cpu = 1'b0
    ,line = 1'b1
} write_enmux_sel_t;
endpackage