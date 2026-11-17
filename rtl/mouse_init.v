//A PS/2 mouse doesn’t start sending movement packets on its own
//After power-up, the computer has to send it a command to start. 
//Every time the mouse receives a command, it answers with an acknowledge byte, 0xFA (“ACK”, meaning “got it”). 
//So when this module sees 0xFA, it knows the mouse has accepted a command and is responding.
`timescale 1ns/1ps
module mouse_init (
    input            clk,
    input            resetn,
    input            rx_valid,
    input      [7:0] rx_data,
    output reg       init_done //1 once the mouse has acknowledged
);
    always @(posedge clk) begin
        if (!resetn)
            init_done <= 0;
        else if (rx_valid && rx_data == 8'hFA) //0xFA
            init_done <= 1;
    end
endmodule
