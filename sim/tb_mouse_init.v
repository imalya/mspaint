
`timescale 1ns/1ps
module tb_mouse_init;
    reg clk = 0, resetn = 0, rx_valid = 0;
    reg [7:0] rx_data = 0;
    wire init_done;
    integer errors = 0;

    always #10 clk = ~clk;
    mouse_init dut (.clk(clk), .resetn(resetn), .rx_valid(rx_valid), .rx_data(rx_data),
                    .init_done(init_done));

    task rx(input [7:0] d);
        begin
            @(negedge clk); rx_valid = 1; rx_data = d;
            @(negedge clk); rx_valid = 0; rx_data = 0;
        end
    endtask

    task check(input cond, input [8*64-1:0] name);
        begin
            if (cond) $display("PASS %0s", name);
            else begin errors = errors + 1; $display("FAIL %0s", name); end
        end
    endtask

    initial begin
        $dumpfile("tb_mouse_init.vcd"); $dumpvars(0, tb_mouse_init);
        repeat (3) @(negedge clk); resetn = 1;
        repeat (3) @(negedge clk);
        check(init_done == 0, "not done after reset");
        rx(8'hAA); rx(8'h00);                        // power-up self-test bytes
        check(init_done == 0, "ignores 0xAA / 0x00 self-test bytes");
        rx(8'hFA);
        check(init_done == 1, "done after 0xFA ack");
        rx(8'h08);
        check(init_done == 1, "stays done while packets arrive");
        @(negedge clk); resetn = 0; @(negedge clk); resetn = 1;
        check(init_done == 0, "reset clears init_done");
        if (errors == 0) $display("RESULT: ALL PASS");
        else             $display("RESULT: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
