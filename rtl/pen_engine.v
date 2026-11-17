
`timescale 1ns/1ps
module pen_engine (
    input         clk,
    input         resetn,
    input         button, //1 while mouse button is held down
    input  [7:0]  cursor_x,   // 0..159 (already clamped by the mouse block) //cursor coords
    input  [7:0]  cursor_y,   // 0..119 //cursor coords
    input  [2:0]  colour, //currently selected colour
    //outputs that connect to canvas ram
    output reg        we,
    output reg [14:0] waddr,
    output reg [2:0]  wdata
);
    always @(posedge clk) begin
        if (!resetn) begin
            we <= 0; waddr <= 0; wdata <= 0; //nothing gets drawn
        end else begin
            we <= 0; //default set to zero
            if (button && cursor_x < 160 && cursor_y < 120) begin //draw if button is held and inside canvas
                we    <= 1; //write now
                waddr <= cursor_y * 160 + cursor_x; //choses position
                wdata <= colour; //chosen color
            end
        end
    end
endmodule
