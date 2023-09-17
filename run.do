vlib work
vlog FIFO.v timer_input.v UART.v uart_rx.v uart_tx.v UART_tb.sv
vsim -voptargs=+acc work.UART_tb

add wave *
run -all
