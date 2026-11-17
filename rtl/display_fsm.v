
`timescale 1ns/1ps
module display_fsm (
    input         clk,
    input         resetn,
    output reg [14:0] raddr,
    input      [2:0]  q,
    output reg [7:0]  vga_x,
    output reg [7:0]  vga_y,
    output reg [8:0]  vga_colour,
    output reg        vga_plot
);
    reg [7:0] x, y;
    reg       v1;
    reg [7:0] x1, y1, x2, y2;
    reg       v2;

    // Stage 0: generate address
    always @(posedge clk) begin
        if (!resetn) begin
            x <= 0; y <= 0; raddr <= 0; v1 <= 0;
        end else begin
            v1    <= 1;
            x1    <= x;
            y1    <= y;
            raddr <= y * 160 + x;
            if (x == 159) begin
                x <= 0;
                y <= (y == 119) ? 0 : y + 1;
            end else
                x <= x + 1;
        end
    end

    // Stage 1: coordinates wait one more clock for the canvas data
    always @(posedge clk) begin
        if (!resetn) begin
            v2 <= 0;
        end else begin
            v2 <= v1; x2 <= x1; y2 <= y1;
        end
    end

    // Stage 2: canvas data (q) arrives 1 clock after raddr; send pixel to VGA
    always @(posedge clk) begin
        if (!resetn) begin
            vga_plot <= 0;
        end else begin
            vga_plot   <= v2;
            vga_x      <= x2;
            vga_y      <= y2;
            vga_colour <= {{3{q[2]}}, {3{q[1]}}, {3{q[0]}}};
        end
    end
endmodule
