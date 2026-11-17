
`timescale 1ns/1ps
module tb_toolbar;
    reg clk = 0, resetn = 0, button = 0;
    reg [7:0] cx = 0, cy = 0;
    wire       sel_valid;
    wire [2:0] sel_colour;
    integer errors = 0, pulses = 0;

    always #10 clk = ~clk;
    toolbar dut (.clk(clk), .resetn(resetn), .cursor_x(cx), .cursor_y(cy), .button(button),
                 .sel_valid(sel_valid), .sel_colour(sel_colour));
    always @(posedge clk) if (sel_valid) pulses = pulses + 1;

    // move the cursor, press and hold the button for 3 cycles, release
    task click(input [7:0] x, input [7:0] y, input expect_sel, input [2:0] ecol, input [8*32-1:0] name);
        integer before, delta;
        begin
            @(negedge clk); cx = x; cy = y; button = 0;
            @(negedge clk); before = pulses;
            button = 1;
            repeat (3) @(negedge clk);
            button = 0;
            @(negedge clk);
            delta = pulses - before;
            if (delta == (expect_sel ? 1 : 0) && (!expect_sel || sel_colour == ecol))
                $display("PASS %0s: pulses=%0d colour=%0d", name, delta, sel_colour);
            else begin
                errors = errors + 1;
                $display("FAIL %0s: pulses=%0d colour=%0d (expected pulses=%0d colour=%0d)",
                         name, delta, sel_colour, expect_sel ? 1 : 0, ecol);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_toolbar.vcd"); $dumpvars(0, tb_toolbar);
        repeat (3) @(negedge clk); resetn = 1;

        click(5,   60,  0, 0, "drawing area click ignored");
        click(100, 111, 0, 0, "row just above palette ignored");
        click(5,   115, 1, 0, "swatch 0 (x=5)");
        click(19,  115, 1, 0, "swatch 0 edge (x=19)");
        click(20,  115, 1, 1, "swatch 1 start (x=20)");
        click(40,  115, 1, 2, "swatch 2");
        click(60,  118, 1, 3, "swatch 3, bottom row");
        click(80,  112, 1, 4, "swatch 4, top palette row");
        click(100, 119, 1, 5, "swatch 5");
        click(120, 115, 1, 6, "swatch 6");
        click(159, 115, 1, 7, "swatch 7 (right edge)");

        if (errors == 0) $display("RESULT: ALL PASS");
        else             $display("RESULT: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
