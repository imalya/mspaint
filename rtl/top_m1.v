
`timescale 1ns/1ps
module top_m1 (
    input         CLOCK_50,
    input  [3:0]  KEY,
    input  [9:0]  SW,
    output [7:0]  VGA_R, VGA_G, VGA_B,
    output        VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK
);
    wire resetn = KEY[0];

    // debounce-style single pulses for the cursor moves
    reg k1, k2, k1d, k2d;
    always @(posedge CLOCK_50) begin
        k1 <= ~KEY[1]; k2 <= ~KEY[2];
        k1d <= k1; k2d <= k2;
    end
    wire step_right = k1 & ~k1d;
    wire step_down  = k2 & ~k2d;

    reg [7:0] cx, cy;
    always @(posedge CLOCK_50) begin
        if (!resetn) begin cx <= 80; cy <= 60; end
        else begin
            if (step_right) cx <= (cx == 159) ? 0 : cx + 1;
            if (step_down)  cy <= (cy == 119) ? 0 : cy + 1;
        end
    end

    wire [14:0] raddr; wire [2:0] q;
    wire we; wire [14:0] waddr; wire [2:0] wdata;

    pen_engine pen (.clk(CLOCK_50), .resetn(resetn), .button(~KEY[3]),
        .cursor_x(cx), .cursor_y(cy), .colour(SW[2:0]),
        .we(we), .waddr(waddr), .wdata(wdata));

    canvas_ram ram (.clk(CLOCK_50), .we(we), .waddr(waddr), .wdata(wdata),
        .raddr(raddr), .q(q));

    wire [7:0] vx, vy; wire [8:0] vc; wire vp;
    display_fsm disp (.clk(CLOCK_50), .resetn(resetn), .raddr(raddr), .q(q),
        .vga_x(vx), .vga_y(vy), .vga_colour(vc), .vga_plot(vp));

    // course VGA adapter (starter code, cite it), matched to vga_adapter.v.
    // x is 8 bits and y is 7 bits at 160x120. write = 1 stores colour at (x, y).
    vga_adapter VGA (
        .resetn(resetn), .clock(CLOCK_50), .color(vc),
        .x(vx[7:0]), .y(vy[6:0]), .write(vp),
        .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B),
        .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N), .VGA_CLK(VGA_CLK));
    defparam VGA.RESOLUTION   = "160x120";
    defparam VGA.COLOR_DEPTH  = 9;            // 3 bits per channel, matches vc
    defparam VGA.BACKGROUND_IMAGE = "black_160x120.mif";
endmodule
