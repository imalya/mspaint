// AI-ASSISTED (Claude): display test. Fills the canvas with a known pattern
// and checks that the VGA outputs visit every pixel once, in raster order, with the right colour.
`timescale 1ns/1ps
module tb_display;
    reg clk = 0, resetn = 0;
    wire [14:0] raddr; wire [7:0] vx, vy; wire [8:0] vc; wire vp;
    reg [2:0] pix [0:19199];
    wire [2:0] q;
    integer n = 0, errors = 0, i, fx, fy;
    canvas_ram ram (.clk(clk), .we(1'b0), .waddr(15'd0), .wdata(3'd0), .raddr(raddr), .q(q));
    display_fsm dut (.clk(clk), .resetn(resetn), .raddr(raddr), .q(q),
        .vga_x(vx), .vga_y(vy), .vga_colour(vc), .vga_plot(vp));
    always #10 clk = ~clk;

    initial begin
        // preload canvas: colour = (x + y) mod 8
        for (i = 0; i < 19200; i = i + 1) begin
            fx = i % 160; fy = i / 160;
            ram.mem[i] = (fx + fy) % 8;
        end
    end

    reg [2:0] ec;
    reg [8:0] evc;
    always @(posedge clk) if (resetn && vp && n < 19200) begin
        fx = n % 160; fy = n / 160;
        ec = (fx + fy) % 8;
        evc = {{3{ec[2]}}, {3{ec[1]}}, {3{ec[0]}}};
        if (vx !== fx || vy !== fy || vc !== evc) begin
            errors = errors + 1;
            if (errors < 5) $display("FAIL pixel %0d: got (%0d,%0d) colour %h", n, vx, vy, vc);
        end
        n = n + 1;
    end

    initial begin
        $dumpfile("tb_display.vcd"); $dumpvars(0, tb_display);
        repeat (3) @(negedge clk); resetn = 1;
        wait (n == 19200);
        repeat (2) @(negedge clk);
        $display("pixels checked: %0d", n);
        $display("tb_display: %s", (errors == 0 && n == 19200) ? "PASS" : "FAIL");
        $finish;
    end
endmodule
