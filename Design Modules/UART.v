
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/02/2023 02:33:04 AM
// Design Name: 
// Module Name: UART
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


module UART
#(parameter DATA_BITS=8,
            STOP_BIT_TICKS = 16,  // determining number of stop bits
            FIFO_DEPTH = 32,
            TIMER_BITS = 11,
            TICKS_PER_DATABIT =16
 )
(
    input clk, reset_n,
    
    //trasnmitter ports
    input [DATA_BITS-1:0] w_data,
    input wr_uart,
    output tx_full,
    output tx,
    
    //receiver ports 
    input rx,
    input rd_uart,
    output [DATA_BITS-1:0] r_data,
    output rx_empty,
    output parity_error,
    
    //Baud rate timer
    input [TIMER_BITS-1 :0] timer_final_value
    );


    
    //signals declaration
    wire [DATA_BITS-1:0] tx_din, rx_dout;
    wire rx_done_tick, tx_done_tick;
    wire tx_empty;
    wire timer_tick;
    wire rx_full_sig;
    wire baudrate_gen_en;
    
    //transmitter instantiation
    uart_tx #(.DATA_BITS(DATA_BITS), .STOP_BIT_TICKS(STOP_BIT_TICKS), .TICKS_PER_DATABIT(TICKS_PER_DATABIT)) transmitter(
        .clk(clk),
        .reset_n(reset_n),
        .timer_tick(timer_tick),
        .tx_din(tx_din),
        .tx_start(~tx_empty),
        .baudrate_gen_en(baudrate_gen_en),
        .tx_done_tick(tx_done_tick),
        .tx(tx)   
    );
    
    //receiver instantiation
    uart_rx #(.DATA_BITS(DATA_BITS), .STOP_BIT_TICKS(STOP_BIT_TICKS), .TICKS_PER_DATABIT(TICKS_PER_DATABIT)) receiver (
        .clk(clk),
        .parity_error (parity_error),
        .reset_n(reset_n),
        .full(rx_full_sig),
        .rx(rx),
        .timer_tick(timer_tick),
        .rx_dout(rx_dout),
        .rx_done_tick(rx_done_tick)
    );
    
    //rx_FIFO instantiation
    FIFO #(.DEPTH(FIFO_DEPTH), .DATA_BITS(DATA_BITS)) rx_FIFO (
      .clk(clk),      // input wire clk
      .reset_n(reset_n),    // input wire srst
      .data_in(rx_dout),      // input wire [7 : 0] din
      .write_en(rx_done_tick),  // input wire wr_en
      .read_en(rd_uart),  // input wire rd_en
      .data_out(r_data),    // output wire [7 : 0] dout
      .full(rx_full_sig),         // output wire full
      .empty(rx_empty)  // output wire empty
    );
    
    //tx_FIFO instantiation
    FIFO #(.DEPTH(FIFO_DEPTH), .DATA_BITS(DATA_BITS)) tx_FIFO (
      .clk(clk),      // input wire clk
      .reset_n(reset_n),    // input wire srst
      .data_in(w_data),      // input wire [7 : 0] din
      .write_en(wr_uart),  // input wire wr_en
      .read_en(tx_done_tick),  // input wire rd_en
      .data_out(tx_din),    // output wire [7 : 0] dout
      .full(tx_full),    // output wire full
      .empty(tx_empty)  // output wire empty
    );
    
    //baud rate generator
    timer_input #(.BITS(TIMER_BITS)) baud_rate_generator (
        .clk(clk),
        .reset_n(reset_n),
        .enable(baudrate_gen_en),
        .final_value(timer_final_value),
        .done(timer_tick)
    );
endmodule
