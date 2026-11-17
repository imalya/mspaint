
`timescale 1ns/1ps
module pen_engine (
    input         clk,
    input         resetn,
    input         button,
    input  [7:0]  cursor_x,   // 0..159 (already clamped by the mouse block)
    input  [7:0]  cursor_y,   // 0..119
    input  [2:0]  colour,
    output reg        we,
    output reg [14:0] waddr,
    output reg [2:0]  wdata
);
    always @(posedge clk) begin
        if (!resetn) begin
            we <= 0; waddr <= 0; wdata <= 0;
        end else begin
            we <= 0;
            if (button && cursor_x < 160 && cursor_y < 120) begin
                we    <= 1;
                waddr <= cursor_y * 160 + cursor_x;
                wdata <= colour;
            end
        end
    end
endmodule
