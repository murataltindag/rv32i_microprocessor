// based on https://www.javatpoint.com/verilog-d-latch

module latch #(width = 32)
(  
    input clk,
    input logic [width-1:0] d,         
    input logic en,      
    input logic rst,       
    output logic [width-1:0] q
);     
        
    always @ (posedge clk) 
    begin
        if (rst) begin
            q <= 0; 
        end 
        else  begin
            if (en)  
                q <= d;  
        end
    end
endmodule : latch