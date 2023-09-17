
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/02/2023 03:22:26 AM
// Design Name: 
// Module Name: uart_rx
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


module uart_rx
#(parameter DATA_BITS=4, 
            STOP_BIT_TICKS = 16,
            TICKS_PER_DATABIT = 16)
(
    input clk, reset_n,
    input rx,
    input full,
    input timer_tick,
    output [DATA_BITS-1 :0] rx_dout,
    output reg rx_done_tick,
    output reg parity_error
    );
    
    //////////////////////////////////////////////// State Encryption ///////////////////////////////////////////////
    localparam idle_state   = 3'b000,
               start_state  = 3'b001,
               data_state   = 3'b010,
               parity_state = 3'b011,
               stop_state   = 3'b100;
    
   /////////////////////////////////////////////// Signals Declaration ///////////////////////////////////////////////
   reg [2:0] state_reg, state_next;  
   reg [5:0] timer_tick_counter_next, timer_tick_counter_reg;
   reg [5:0] received_bits_counter_next, received_bits_counter_reg; 
   reg [DATA_BITS-1 :0] SI_next, SI_reg; 

   reg parity_bit;

   /*this flag is used to make read operation happen at one positive edge only and not read the same 
    value multiple times */
   reg read_flag;


   wire calculated_parity;
    
    /////////////////////////////////////////////// Sequential Logic ///////////////////////////////////////////////
    always@(posedge clk, negedge reset_n)
    begin
        if(~reset_n) begin
            state_reg <= idle_state;

            timer_tick_counter_reg <= 0;
            received_bits_counter_reg <= 0;

            SI_reg = 0;
        end
        else begin
            state_reg <= state_next;

            timer_tick_counter_reg <= timer_tick_counter_next;
            received_bits_counter_reg <= received_bits_counter_next;

            SI_reg <= SI_next;
        end
    end
    
    
    //////////////////////////////////////////////// Next State Logic ///////////////////////////////////////////////
    always@(*) begin
        case(state_reg)
            idle_state: begin
                timer_tick_counter_next = 0;
                received_bits_counter_next = 0;
                read_flag = 0;

                if(full) 
                    state_next = idle_state;
                else if(rx)
                    state_next = idle_state;
                else 
                    state_next = start_state;     
            end

            /////////////////////////////////////////////////////
            start_state: begin

                if(timer_tick) begin
                    timer_tick_counter_next = timer_tick_counter_reg + 1;
                    if(timer_tick_counter_reg == (TICKS_PER_DATABIT-1)/2) begin
                        timer_tick_counter_next = 0;
                        state_next = data_state;
                        end
                    else begin
                        state_next = start_state;
                    end
                end
            end
            
            /////////////////////////////////////////////////////
            data_state: begin
                if(timer_tick) begin
                    timer_tick_counter_next = timer_tick_counter_reg + 1;
                    
                    if(timer_tick_counter_reg == TICKS_PER_DATABIT-1) begin
                        SI_next = {rx, SI_reg[DATA_BITS-1:1]};
                        received_bits_counter_next = received_bits_counter_reg + 1;
                        timer_tick_counter_next = 0;
                        
                        if(received_bits_counter_reg == DATA_BITS -1) begin  
                            state_next  = parity_state;
                            received_bits_counter_next = 0;
                        end
                        else begin
                            state_next = data_state;
                        end
                        
                    end
                    else begin
                        state_next = data_state;
                    end
                    
                end
                else begin
                    state_next = data_state;
                end
            end
            
            /////////////////////////////////////////////////////
            parity_state: begin
                if(timer_tick) begin
                    timer_tick_counter_next = timer_tick_counter_reg + 1;

                    if(timer_tick_counter_reg == TICKS_PER_DATABIT - 1) begin
                        timer_tick_counter_next = 0;
                        state_next = stop_state;
                    end
                    else begin
                        state_next = parity_state;
                    end
                end
                else begin
                    state_next = parity_state;
                end
            end
            
            /////////////////////////////////////////////////////
            stop_state: begin 
                read_flag = 0;
                if(timer_tick) begin
                    timer_tick_counter_next = timer_tick_counter_reg + 1;

                    if(timer_tick_counter_reg == STOP_BIT_TICKS -1) begin 
                        timer_tick_counter_next = timer_tick_counter_reg + 1; 
                        state_next = stop_state;
                        read_flag = 1;
                    end
                    else if(timer_tick_counter_reg == (STOP_BIT_TICKS + (STOP_BIT_TICKS/2) - 1) )begin   
                        timer_tick_counter_next = 0;                    
                        if(rx) 
                            state_next = idle_state;
                        else 
                            state_next = start_state;                  
                    end   
                end
                else begin
                    state_next = stop_state;
                end
            end
        endcase
    end
    
   //////////////////////////////////////// Output Logic ////////////////////////////////////// 
    assign rx_dout = SI_reg;
    assign calculated_parity = ^rx_dout;

    
   //rx_done_tick logic
   always@(*) begin
       if(state_reg == stop_state) begin
           if(read_flag) 
               rx_done_tick = 1;
           else 
               rx_done_tick = 0;
       end
       else begin
              rx_done_tick = 0;
       end
   end

   //parity_error logic
   always@(*) begin
       if(state_reg == stop_state) begin
           if(timer_tick_counter_reg == TICKS_PER_DATABIT - 1) begin
               parity_bit = rx;

                ////////////////// checking parity bit /////////////////
                if (parity_bit == calculated_parity)
                    parity_error = 1'b0;
                else 
                    parity_error = 1'b1;
           end
           else begin
               parity_error = 0;
           end
       end
       else begin
           parity_error = 0;
       end
   end    
endmodule
