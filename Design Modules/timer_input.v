
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/02/2023 03:21:56 AM
// Design Name: 
// Module Name: timer_input
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


module timer_input
#(parameter BITS =4)
(
    input clk,
    input reset_n,
    input enable,
    input [BITS-1:0] final_value, 
    output done
    );
    
    reg [BITS-1:0] Q;
    
    always@(posedge clk, negedge reset_n)
    begin
        if(~reset_n) 
            Q <= 'b0;
        else if(enable) begin
            if(~done) 
                Q <= Q+1;
            else
                Q <= 'b0;
        end
    end
    
    //output logic
    assign done = (Q == final_value);
endmodule
