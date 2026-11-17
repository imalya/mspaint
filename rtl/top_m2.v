
`timescale 1ns/1ps
module top_m2 (
    input         CLOCK_50,
    input  [3:0]  KEY,
    inout         PS2_CLK,
    inout         PS2_DAT,
    output [9:0]  LEDR,
    output [7:0]  VGA_R, VGA_G, VGA_B,
    output        VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK
);
    localparam MOVE_SHIFT  = 1;      // divide mouse movement by 2 (0 = full speed)
    localparam PALETTE_TOP = 112;

    wire resetn = KEY[0];

    // ---------------- PS/2 mouse ----------------
    wire [7:0] rx_data;
    wire       rx_valid;
    PS2_Controller #(.INITIALIZE_MOUSE(1)) PS2 (
        .CLOCK_50(CLOCK_50), .reset(~resetn),           // core reset is active high
        .the_command(8'h00), .send_command(1'b0),
        .PS2_CLK(PS2_CLK), .PS2_DAT(PS2_DAT),
        .command_was_sent(), .error_communication_timed_out(),
        .received_data(rx_data), .received_data_en(rx_valid));

    wire init_done;
    mouse_init init (.clk(CLOCK_50), .resetn(resetn),
        .rx_valid(rx_valid), .rx_data(rx_data), .init_done(init_done));

    wire pkt_valid; wire [2:0] btn; wire signed [8:0] dx, dy;
    mouse_packet_parser parser (.clk(CLOCK_50), .resetn(resetn & init_done),
        .rx_valid(rx_valid & init_done), .rx_data(rx_data),
        .pkt_valid(pkt_valid), .btn(btn), .dx(dx), .dy(dy));

    wire signed [8:0] dx_s = dx >>> MOVE_SHIFT;
    wire signed [8:0] dy_s = dy >>> MOVE_SHIFT;

    wire [7:0] cx, cy; wire button;
    mouse_tracker tracker (.clk(CLOCK_50), .resetn(resetn), .pkt_valid(pkt_valid),
        .btn(btn), .dx(dx_s), .dy(dy_s),
        .cursor_x(cx), .cursor_y(cy), .button(button));

    // ---------------- toolbar / pen colour ----------------
    wire sel_valid; wire [2:0] sel_colour;
    toolbar tools (.clk(CLOCK_50), .resetn(resetn), .cursor_x(cx), .cursor_y(cy),
        .button(button), .sel_valid(sel_valid), .sel_colour(sel_colour));

    reg [2:0] pen_colour;
    always @(posedge CLOCK_50) begin
        if (!resetn)        pen_colour <= 3'b111;       // white
        else if (sel_valid) pen_colour <= sel_colour;
    end

    // ---------------- canvas ----------------
    wire [14:0] raddr; wire [2:0] q;
    wire we; wire [14:0] waddr; wire [2:0] wdata;

    // no drawing on the palette rows
    pen_engine pen (.clk(CLOCK_50), .resetn(resetn),
        .button(button && cy < PALETTE_TOP),
        .cursor_x(cx), .cursor_y(cy), .colour(pen_colour),
        .we(we), .waddr(waddr), .wdata(wdata));

    canvas_ram ram (.clk(CLOCK_50), .we(we), .waddr(waddr), .wdata(wdata),
        .raddr(raddr), .q(q));

    wire [7:0] vx, vy; wire [8:0] vc; wire vp;
    display_fsm disp (.clk(CLOCK_50), .resetn(resetn), .raddr(raddr), .q(q),
        .vga_x(vx), .vga_y(vy), .vga_colour(vc), .vga_plot(vp));

    // ---------------- overlays: palette and cursor ----------------
    wire [2:0] swatch = vx / 20;
    wire [8:0] swatch_rgb = {{3{swatch[2]}}, {3{swatch[1]}}, {3{swatch[0]}}};
    reg  [8:0] out_colour;
    always @(*) begin
        if (vx == cx && vy == cy)    out_colour = ~vc;           // cursor
        else if (vy >= PALETTE_TOP)  out_colour = swatch_rgb;    // palette
        else                         out_colour = vc;            // canvas
    end

    vga_adapter VGA (
        .resetn(resetn), .clock(CLOCK_50), .color(out_colour),
        .x(vx[7:0]), .y(vy[6:0]), .write(vp),
        .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B),
        .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N), .VGA_CLK(VGA_CLK));
    defparam VGA.RESOLUTION       = "160x120";
    defparam VGA.COLOR_DEPTH      = 9;
    defparam VGA.BACKGROUND_IMAGE = "black_160x120.mif";

    assign LEDR = {5'b0, pen_colour, button, init_done};
endmodule
