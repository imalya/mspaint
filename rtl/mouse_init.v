
`timescale 1ns/1ps
module mouse_init (
    input            clk,
    input            resetn,
    input            rx_valid,
    input      [7:0] rx_data,
    output reg       init_done
);
    always @(posedge clk) begin
        if (!resetn)
            init_done <= 0;
        else if (rx_valid && rx_data == 8'hFA)
            init_done <= 1;
    end
endmodule
