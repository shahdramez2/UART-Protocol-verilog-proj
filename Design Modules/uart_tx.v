
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/02/2023 03:23:45 AM
// Design Name: 
// Module Name: uart_tx
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


module uart_tx
#(parameter DATA_BITS=4, STOP_BIT_TICKS = 16 , TICKS_PER_DATABIT = 16)
(
    input clk, reset_n,
    input [DATA_BITS-1:0] tx_din,
    input tx_start,
    input timer_tick,
    output baudrate_gen_en,
    output reg tx_done_tick,
    output reg  tx
    );
    
     ///////////////////////////////////////// State Encryption /////////////////////////////////////////////////
     localparam   idle_state   = 3'b000,
                  start_state  = 3'b001,
                  data_state   = 3'b010,
                  parity_state = 3'b011,
                  stop_state   = 3'b100;
      
      ///////////////////////////////////////////// Signals Declaration ////////////////////////////////////////////////
   
      reg [2:0] state_reg, state_next;  
      reg [5:0] timer_tick_counter_next, timer_tick_counter_reg ;
      reg [5:0] sent_bits_counter_next, sent_bits_counter_reg; 

      wire calculated_parity;
      
      
      ///////////////////////////////////////////////// Sequential Logic //////////////////////////////////////////////// 
       always@(posedge clk, negedge reset_n)
       begin
           if(~reset_n) begin
               state_reg <= idle_state;

               timer_tick_counter_reg <= 0;
               sent_bits_counter_reg <= 0;
           end
           else begin
               state_reg <= state_next;
               timer_tick_counter_reg <= timer_tick_counter_next;
               sent_bits_counter_reg <= sent_bits_counter_next;
           end
       end
       
        //////////////////////////////////////////////// Next State Logic //////////////////////////////////////////////// 
          always@(*) begin
              case(state_reg) 
              idle_state: begin

                    timer_tick_counter_next = 0;
                    sent_bits_counter_next = 0;
                    tx = 1'b1;

                    if(tx_start) begin
                        state_next = start_state;
                        tx = 0;
                    end
                    else 
                        state_next = idle_state;
              end
              
              /////////////////////////////////////////////////////
              start_state: begin
                    if(timer_tick) begin
                        timer_tick_counter_next = timer_tick_counter_reg + 1;
                        if(timer_tick_counter_reg == (TICKS_PER_DATABIT -1) ) begin
                            timer_tick_counter_next = 0;
                            state_next = data_state;
                            tx = tx_din [sent_bits_counter_reg];
                        end
                        else begin
                            state_next = start_state;
                        end   
                    end
                    else begin
                        state_next = start_state;
                    end
              end
              
              /////////////////////////////////////////////////////
              data_state: begin
                   tx = tx_din [sent_bits_counter_reg];

                    if(timer_tick) begin
                        timer_tick_counter_next = timer_tick_counter_reg + 1;
                        
                        if(timer_tick_counter_reg == TICKS_PER_DATABIT -1) begin
                            sent_bits_counter_next = sent_bits_counter_reg + 1;
                            timer_tick_counter_next = 0;
                            
                            if(sent_bits_counter_reg == DATA_BITS -1) begin
                                state_next = parity_state;
                                tx = calculated_parity;
                                sent_bits_counter_next = 0; 
                            end
                            else
                                state_next = data_state;
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
                   tx = calculated_parity;
                    if (timer_tick) begin
                        timer_tick_counter_next = timer_tick_counter_reg + 1;

                        if(timer_tick_counter_reg == TICKS_PER_DATABIT -1) begin
                            timer_tick_counter_next = 0;
                            state_next = stop_state;
                            tx = 1'b1;
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
                    //tx = 1'b1;
                    
                    if(timer_tick) begin
                        timer_tick_counter_next = timer_tick_counter_reg + 1;
                        
                        if(timer_tick_counter_reg == STOP_BIT_TICKS -1) begin
                            timer_tick_counter_next = 0;
                            state_next = idle_state;
                            
                            if(tx_start) begin
                                state_next = start_state;
                                tx = 0;
                            end
                            else begin
                                state_next = idle_state;
                                tx = 1;
                            end 
                        end
                    end
                    else begin
                        state_next = stop_state;
                    end
              
              end
              
              endcase
      end

///////////////////////////////////////////// output logic //////////////////////////////////////////
assign calculated_parity = ^tx_din;


always@(*) begin
    if(state_reg == start_state && state_next == data_state) 
        tx_done_tick = 1;
    else 
        tx_done_tick = 0;
end

assign baudrate_gen_en = (state_reg == idle_state)? 1'b0 : 1'b1;

endmodule
