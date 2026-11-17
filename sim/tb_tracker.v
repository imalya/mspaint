// AI-ASSISTED (Claude): testbench for mouse_tracker (position tracking + edge clamping).
`timescale 1ns/1ps
module tb_tracker;
    reg clk = 0, resetn = 0, pkt_valid = 0;
    reg [2:0] btn = 0;
    reg signed [8:0] dx = 0, dy = 0;
    wire [7:0] cx, cy;
    wire       button;
    integer errors = 0;

    always #10 clk = ~clk;
    mouse_tracker dut (.clk(clk), .resetn(resetn), .pkt_valid(pkt_valid), .btn(btn),
                       .dx(dx), .dy(dy), .cursor_x(cx), .cursor_y(cy), .button(button));

    task move(input signed [8:0] mx, input signed [8:0] my, input [2:0] b);
        begin
            @(negedge clk); dx = mx; dy = my; btn = b; pkt_valid = 1;
            @(negedge clk); pkt_valid = 0;
        end
    endtask

    task check(input [7:0] ex, input [7:0] ey, input eb, input [8*32-1:0] name);
        begin
            if (cx == ex && cy == ey && button == eb)
                $display("PASS %0s: cursor=(%0d,%0d) button=%b", name, cx, cy, button);
            else begin
                errors = errors + 1;
                $display("FAIL %0s: cursor=(%0d,%0d) button=%b, expected (%0d,%0d) button=%b",
                         name, cx, cy, button, ex, ey, eb);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_tracker.vcd"); $dumpvars(0, tb_tracker);
        repeat (3) @(negedge clk); resetn = 1;
        check(80, 60, 0, "reset to centre");

        move(5, 3, 0);     check(85, 57, 0, "right 5, up 3");
        move(-10, -4, 1);  check(75, 61, 1, "left 10, down 4, button on");
        move(-158, 0, 0);  check(0, 61, 0, "left, exact stop at x=0");
        move(-255, 0, 0);  check(0, 61, 0, "clamp at left edge (no wrap)");
        move(0, 255, 0);   check(0, 0, 0, "clamp at top edge");
        move(255, -255, 0);check(159, 119, 0, "clamp at right/bottom corner");
        move(0, -1, 0);    check(159, 119, 0, "stays at bottom edge");
        move(-1, 0, 0);    check(158, 119, 0, "one step left from corner");
        move(0, 0, 0);     check(158, 119, 0, "zero movement keeps position");

        if (errors == 0) $display("RESULT: ALL PASS");
        else             $display("RESULT: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
