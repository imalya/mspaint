// AI-ASSISTED (Claude): pen test. Holds the button and moves the cursor from
// (10,10) to (20,10). Expects 11 writes in colour 6 at row 10, and no writes when the button is up.
`timescale 1ns/1ps
module tb_pen_engine;
    reg clk = 0, resetn = 0, button = 0;
    reg [7:0] cx = 10, cy = 10;
    reg [2:0] colour = 3'd6;
    wire we; wire [14:0] waddr; wire [2:0] wdata;
    integer writes = 0, errors = 0, i;
    pen_engine dut (.clk(clk), .resetn(resetn), .button(button),
        .cursor_x(cx), .cursor_y(cy), .colour(colour),
        .we(we), .waddr(waddr), .wdata(wdata));
    always #10 clk = ~clk;

    always @(posedge clk) if (we) begin
        writes = writes + 1;
        if (wdata !== 3'd6 || waddr !== (10*160 + 10 + writes - 1)) begin
            errors = errors + 1;
            $display("FAIL write %0d: addr %0d colour %0d", writes, waddr, wdata);
        end
    end

    initial begin
        $dumpfile("tb_pen_engine.vcd"); $dumpvars(0, tb_pen_engine);
        repeat (2) @(negedge clk); resetn = 1;
        // button up: moving the cursor must not write
        for (i = 10; i <= 20; i = i + 1) begin cx = i; @(negedge clk); end
        if (writes != 0) begin errors = errors + 1; $display("FAIL: wrote %0d pixels with button up", writes); end
        writes = 0;
        // button down at (10,10), then move to (20,10)
        cx = 10; @(negedge clk);
        button = 1;
        for (i = 10; i <= 20; i = i + 1) begin cx = i; @(negedge clk); end
        button = 0;
        repeat (3) @(negedge clk);
        if (writes != 11) begin errors = errors + 1; $display("FAIL: expected 11 writes, got %0d", writes); end
        else $display("ok   11 pen writes along row 10");
        $display("tb_pen_engine: %s", errors == 0 ? "PASS" : "FAIL");
        $finish;
    end
endmodule
