module UART_tb ();

///////////////////////////////// Local Parameters//////////////////////////////////////////////////
localparam  DATA_BITS=8;
localparam  TICKS_PER_DATABIT = 4;
localparam  STOP_BIT_TICKS = 4;  // determining number of stop bits
localparam  FIFO_DEPTH = 32;
localparam  TIMER_BITS = 11;

localparam Tclk = 2;

localparam NUM_TEST_WORDS = 6;



///////////////////////////////// Counters ////////////////////////////////////////////////////////
integer falseCases, correctCases, testCases;


///////////////////////////////// Signals Declaration //////////////////////////////////////////////////
bit clk;
bit reset_n;


//receiver signals
logic [DATA_BITS-1 :0] r_data;
logic rx;
logic rx_empty;
logic rd_uart;
logic parity_error;


//transmitter signals
logic tx_full;
logic tx;
logic wr_uart;
logic [DATA_BITS-1 :0] w_data;

logic [10:0] timer_final_value;



bit [DATA_BITS - 1 :0] testWords [NUM_TEST_WORDS];

///////////////////////////////// UART Instantiaion //////////////////////////////////////////////////
UART #(.DATA_BITS      (DATA_BITS), 
	   .STOP_BIT_TICKS (STOP_BIT_TICKS), 
	   .FIFO_DEPTH     (FIFO_DEPTH),
	   .TIMER_BITS     (TIMER_BITS),
	   .TICKS_PER_DATABIT (TICKS_PER_DATABIT))  DUT 
		(

	   		.clk(clk),
	   		.reset_n(reset_n),

	   		.timer_final_value(timer_final_value),

	   		//receiver
	   		.rx       (rx),
	   		.r_data   (r_data),
	   		.rx_empty (rx_empty),
	   		.rd_uart  (rd_uart),
	   		.parity_error (parity_error),


	   		//transmitter
	   		.tx      (tx),
	   		.tx_full (tx_full),
	   		.wr_uart (wr_uart),
	   		.w_data  (w_data)
	   );

///////////////////////////////// assign statements ////////////////////////////////////////////////
assign rx = tx;


///////////////////////////////// Clock Generation //////////////////////////////////////////////////
initial begin
	clk = 1'b0;
	forever #(Tclk/2) clk = ~clk;
end


///////////////////////////////// Preparing Test Stimulus //////////////////////////////////////////////////
initial begin
	for (int i=0; i < NUM_TEST_WORDS; i++) begin
 		testWords [i] = $random;
 	end
end


initial begin
	///////////////////////////////// initialize variables ///////////////////////////
	testCases    =0;
	falseCases   =0;
	correctCases =0;
	rd_uart      = 0;
	w_data =0;
	wr_uart = 0;
	timer_final_value = 2;


	reset_check();

	transmit_data();

	//wait for data to be transmitted
	repeat(Tclk*TICKS_PER_DATABIT*DATA_BITS*NUM_TEST_WORDS*10) @(negedge clk);

	receive_data();

	$display("%t: \n\nEnd of Simulation \nfalseCases = %0d, correctCases = %0d, testCases = %0d", $time, falseCases, correctCases, testCases);
	$stop;
end


///////////////////////////////// Tasks //////////////////////////////////////////////////

task reset_check ();
	reset_n = 1'b0;
	@(negedge clk);
		if (r_data !== 0) begin
			$display("%t: Error in reset functionality, r_data = %0d NOT 0", $time, r_data);
			falseCases ++;
			testCases ++;
		end 
		else begin
			correctCases ++;
			testCases ++;
		end

	reset_n = 1'b1;
endtask
////////////////////////////////
task transmit_data();
	wr_uart = 1;
	for (int i=0; i < NUM_TEST_WORDS; i++) begin
		w_data = testWords [i];
		check_transmitted_data (i);
	end

	wr_uart = 0;
endtask
//////////////////////////////

task receive_data();
	rd_uart = 1;
	for (int i = 0; i < NUM_TEST_WORDS; i++) begin
		check_received_data (i);
	end
endtask
/////////////////////////////

task check_transmitted_data (input [31:0] i);
		
		@(negedge clk);

		if (DUT.tx_FIFO.fifo_mem [i] !== testWords [i]) begin
			$display("%t: Transmitter Error! testWords [%0d] = %0d, while tx_FIFO[%0d] = %0d", $time,i, testWords[i], i, DUT.tx_FIFO.fifo_mem[i]);
			falseCases ++;
			testCases ++;
		end
		else begin
			correctCases ++;
			testCases ++;
		end
endtask

//////////////////////////
task check_received_data (input [31:0] i);
	
		@(negedge clk);

		if (r_data !== testWords [i]) begin
			$display("%t: Receiver Error! testWords [%0d] = %0d, while r_data = %0d", $time, i, testWords[i], r_data);
			falseCases ++;
			testCases ++;
		end
		else begin
			correctCases ++;
			testCases ++;
		end
endtask

endmodule



