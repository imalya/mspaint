
`timescale 1ns/1ps
module tb_packet_parser;
    reg clk = 0, resetn = 0, rx_valid = 0;
    reg  [7:0] rx_data = 0;
    wire       pkt_valid;
    wire [2:0] btn;
    wire signed [8:0] dx, dy;
    integer errors = 0, pulses = 0;

    always #10 clk = ~clk;
    mouse_packet_parser dut (.clk(clk), .resetn(resetn), .rx_valid(rx_valid), .rx_data(rx_data),
                             .pkt_valid(pkt_valid), .btn(btn), .dx(dx), .dy(dy));
    always @(posedge clk) if (pkt_valid) pulses = pulses + 1;

    task send(input [7:0] d);
        begin
            @(negedge clk); rx_valid = 1; rx_data = d;
            @(negedge clk); rx_valid = 0; rx_data = 0;
        end
    endtask

    task expect_pkt(input [2:0] eb, input signed [8:0] edx, input signed [8:0] edy, input [8*32-1:0] name);
        begin
            if (pkt_valid && btn == eb && dx == edx && dy == edy)
                $display("PASS %0s: btn=%b dx=%0d dy=%0d", name, btn, dx, dy);
            else begin
                errors = errors + 1;
                $display("FAIL %0s: pkt_valid=%b btn=%b dx=%0d dy=%0d (expected btn=%b dx=%0d dy=%0d)",
                         name, pkt_valid, btn, dx, dy, eb, edx, edy);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_packet_parser.vcd"); $dumpvars(0, tb_packet_parser);
        repeat (3) @(negedge clk); resetn = 1;

        send(8'h09); send(8'h05); send(8'h03);                 // left button, +5, +3
        expect_pkt(3'b001, 5, 3, "left button, +5 +3");

        send(8'h39); send(8'hFB); send(8'hFD);                 // X and Y sign bits set: -5, -3
        expect_pkt(3'b001, -5, -3, "negative movement -5 -3");

        send(8'h00); send(8'h07);                              // garbage (bit 3 = 0), must be skipped
        send(8'h08); send(8'h00); send(8'h00);                 // real packet with no movement
        expect_pkt(3'b000, 0, 0, "resync after garbage");

        send(8'h0A); send(8'h01); send(8'h00);                 // right button, +1
        expect_pkt(3'b010, 1, 0, "right button +1");

        repeat (2) @(negedge clk);   // let the last pulse be counted
        if (pulses == 4) $display("PASS exactly one pkt_valid pulse per packet (4 packets)");
        else begin errors = errors + 1; $display("FAIL pkt_valid pulses = %0d, expected 4", pulses); end

        if (errors == 0) $display("RESULT: ALL PASS");
        else             $display("RESULT: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
