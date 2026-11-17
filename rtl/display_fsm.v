
//fsm
//when you ask the memory “what’s pixel 5?”, the answer comes one clock later(but then u already moved on to asking about pixel 6.)
//module remembers which pixel it was asking about, so the answer gets paired with the right position. 
//thats what the x1, y1, x2, y2 copies are for.
//a delayed copy of “where I was”, so the color that arrives lines up with the correct spot.
`timescale 1ns/1ps
module display_fsm (
    input         clk,
    input         resetn,
    output reg [14:0] raddr, //goes to canvas read adress
    input      [2:0]  q, //color that comes back
    output reg [7:0]  vga_x, //goes to vga
    output reg [7:0]  vga_y,
    output reg [8:0]  vga_colour,
    output reg        vga_plot
);
    reg [7:0] x, y; //current pixel being scanned
    reg       v1; //valid flags
    reg [7:0] x1, y1, x2, y2; //copy 1 is 1 clock tick behind, 2 is 2 clock ticks behind
    reg       v2;

    // Stage 0: generate address
    always @(posedge clk) begin
        if (!resetn) begin
            x <= 0; y <= 0; raddr <= 0; v1 <= 0;
        end else begin
            v1    <= 1;
            x1    <= x;//save a copy of the pixel
            y1    <= y;
            raddr <= y * 160 + x; //ask the memory for that pixel, using the row-and-column formula
            if (x == 159) begin //at the end of the row
                x <= 0;  //x goes to 0
                y <= (y == 119) ? 0 : y + 1; //and move down one row 
            end else
                x <= x + 1; //otherwise just move one pixel to the right
        end
    end

    // Stage 1: coordinates wait one more clock for the canvas data
    always @(posedge clk) begin
        if (!resetn) begin
            v2 <= 0; 
        end else begin
            v2 <= v1; x2 <= x1; y2 <= y1; //go one step further down, the memory is giving you the color for the pixel u asked for 
        end
    end

    // Stage 2: canvas data (q) arrives 1 clock after raddr; send pixel to VGA
    always @(posedge clk) begin
        if (!resetn) begin
            vga_plot <= 0;
        end else begin
            vga_plot   <= v2;//plot if its valid
            vga_x      <= x2;
            vga_y      <= y2;
            vga_colour <= {{3{q[2]}}, {3{q[1]}}, {3{q[0]}}};//the VGA adapter wants 3 bits each for red, green, and blue (9 total), but canvas only stores 3 bits per pixel, one bit per color.
        end
    end
endmodule
