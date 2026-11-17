
`timescale 1ns/1ps
module tb_mouse_system;
    reg clk = 0, resetn = 0, rx_valid = 0;
    reg [7:0] rx_data = 0;
    integer errors = 0;
    always #10 clk = ~clk;

    wire init_done;
    mouse_init init (.clk(clk), .resetn(resetn), .rx_valid(rx_valid), .rx_data(rx_data),
                     .init_done(init_done));
    wire pkt_valid; wire [2:0] btn; wire signed [8:0] dx, dy;
    mouse_packet_parser parser (.clk(clk), .resetn(resetn & init_done),
        .rx_valid(rx_valid & init_done), .rx_data(rx_data),
        .pkt_valid(pkt_valid), .btn(btn), .dx(dx), .dy(dy));
    wire signed [8:0] dx_s = dx >>> 1, dy_s = dy >>> 1;
    wire [7:0] cx, cy; wire button;
    mouse_tracker tracker (.clk(clk), .resetn(resetn), .pkt_valid(pkt_valid), .btn(btn),
        .dx(dx_s), .dy(dy_s), .cursor_x(cx), .cursor_y(cy), .button(button));
    wire sel_valid; wire [2:0] sel_colour;
    toolbar tools (.clk(clk), .resetn(resetn), .cursor_x(cx), .cursor_y(cy), .button(button),
        .sel_valid(sel_valid), .sel_colour(sel_colour));

    task rx(input [7:0] d);
        begin
            @(negedge clk); rx_valid = 1; rx_data = d;
            @(negedge clk); rx_valid = 0; rx_data = 0;
            repeat (3) @(negedge clk);            // real bytes are far apart
        end
    endtask
    task packet(input [7:0] b0, input [7:0] b1, input [7:0] b2);
        begin rx(b0); rx(b1); rx(b2); end
    endtask
    task check(input cond, input [8*64-1:0] name);
        begin
            if (cond) $display("PASS %0s  (cursor=(%0d,%0d) button=%b colour=%0d)",
                               name, cx, cy, button, sel_colour);
            else begin errors = errors + 1;
                $display("FAIL %0s  (cursor=(%0d,%0d) button=%b colour=%0d)",
                         name, cx, cy, button, sel_colour); end
        end
    endtask

    initial begin
        $dumpfile("tb_mouse_system.vcd"); $dumpvars(0, tb_mouse_system);
        repeat (3) @(negedge clk); resetn = 1;

        packet(8'h08, 8'h0A, 8'h00);              // arrives before the ack: must be ignored
        check(cx == 80 && cy == 60, "packets before 0xFA ignored");

        rx(8'hFA);                                 // ack for the core's 0xF4
        packet(8'h08, 8'h14, 8'h0A);              // +20 right, +10 up -> +10, -5 on screen
        check(cx == 90 && cy == 55, "move right 10, up 5 (after /2)");

        packet(8'h29, 8'h00, 8'hD8);              // left button, dy = -40 -> down 20
        check(cx == 90 && cy == 75 && button == 1, "move down 20 with left button");

        packet(8'h08, 8'h00, 8'h00);              // release
        packet(8'h08, 8'h7F, 8'h00);              // +127 -> +63, clamp at 159
        check(cx == 153 && cy == 75, "right 63");
        packet(8'h08, 8'h7F, 8'h00);
        check(cx == 159, "clamped at right edge");

        packet(8'h28, 8'h00, 8'hB0);              // dy = -80 -> down 40 -> 115 (palette)
        packet(8'h28, 8'h00, 8'hF0);              // dy = -16 -> down 8 -> clamp 119
        check(cy == 119, "clamped at bottom edge");
        packet(8'h18, 8'hB0, 8'h00);              // dx = -80 -> left 40 -> x = 119
        packet(8'h09, 8'h00, 8'h00);              // click
        check(sel_colour == 5, "click on palette at x=119 selects colour 5");
        packet(8'h08, 8'h00, 8'h00);              // release

        if (errors == 0) $display("RESULT: ALL PASS");
        else             $display("RESULT: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
