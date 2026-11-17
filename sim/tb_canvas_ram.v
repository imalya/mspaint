// AI-ASSISTED (Claude): canvas RAM test. Writes and reads back a few addresses.
`timescale 1ns/1ps
module tb_canvas_ram;
    reg clk = 0, we = 0;
    reg [14:0] waddr = 0, raddr = 0;
    reg [2:0]  wdata = 0;
    wire [2:0] q;
    integer errors = 0;
    canvas_ram dut (.clk(clk), .we(we), .waddr(waddr), .wdata(wdata), .raddr(raddr), .q(q));
    always #10 clk = ~clk;
    integer i;
    initial for (i = 0; i < 19200; i = i + 1) dut.mem[i] = 3'd0;   // simulation only

    task write(input [14:0] a, input [2:0] d);
        begin @(negedge clk); we = 1; waddr = a; wdata = d;
              @(negedge clk); we = 0; end
    endtask
    task check(input [14:0] a, input [2:0] exp);
        begin @(negedge clk); raddr = a; @(negedge clk); @(negedge clk);
              if (q !== exp) begin errors = errors + 1;
                  $display("FAIL addr %0d: got %0d expected %0d", a, q, exp); end
              else $display("ok   addr %0d = %0d", a, q); end
    endtask

    initial begin
        $dumpfile("tb_canvas_ram.vcd"); $dumpvars(0, tb_canvas_ram);
        write(0, 3'd5);            // (0,0)
        write(159, 3'd2);          // (159,0)
        write(160, 3'd7);          // (0,1)
        write(19199, 3'd4);        // (159,119), last pixel
        check(0, 3'd5);
        check(159, 3'd2);
        check(160, 3'd7);
        check(19199, 3'd4);
        check(1, 3'd0);            // untouched pixel stays 0
        $display("tb_canvas_ram: %s", errors == 0 ? "PASS" : "FAIL");
        $finish;
    end
endmodule
