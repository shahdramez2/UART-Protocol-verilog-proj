
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/12/2023 09:12:16 PM
// Design Name: 
// Module Name: FIFO
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FIFO
#(parameter DATA_BITS = 8, DEPTH = 32)
(
    input clk,
    input reset_n,
    input write_en,
    input read_en,
    input  [DATA_BITS-1:0] data_in,
    output reg [DATA_BITS-1:0] data_out,
    output full,
    output empty
    );
    
    //one extra bit added to POINTER_BITS to differentiate between empty and full conditions
    localparam POINTER_BITS = $clog2(DEPTH) + 1;  
    
    
   reg [DATA_BITS-1:0] fifo_mem [0: DEPTH-1];
   reg [POINTER_BITS :0] wr_ptr, rd_ptr;
   
   
   
   //read operation
   always@(posedge clk, negedge reset_n) begin
        if(~reset_n) 
            data_out <= 0;
        else if(~empty && read_en) 
            data_out <= fifo_mem [rd_ptr[POINTER_BITS-1:0]];
   end
   
   //write operation
   always @(posedge clk) begin
     if(~full && write_en)  
        fifo_mem[wr_ptr[POINTER_BITS-1:0]] <= data_in;
   end
   
  // read and write pointers
  always@(posedge clk, negedge reset_n) begin
        if(~reset_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end
        else begin
            //write_ptr logic
            if(~full && write_en) begin
                if(wr_ptr == DEPTH-1)
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1;       
             end
             
             //rd_ptr logic
             if(~empty && read_en) begin
                if(rd_ptr == DEPTH-1) 
                    rd_ptr <= 0;
                else 
                    rd_ptr <= rd_ptr + 1;
             end     
        end
  end
   
   //empty and full conditions
   assign empty = (wr_ptr == rd_ptr);
   assign full  = {~wr_ptr[POINTER_BITS], wr_ptr[POINTER_BITS-1:0]} == rd_ptr;  
endmodule
