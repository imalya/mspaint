
`timescale 1ns/1ps
module clear_engine (
    input             clk,
    input             resetn,
    input             start,
    output reg        we,
    output reg [14:0] waddr,
    output reg [2:0]  wdata,
    output            busy,
    output reg        done
);
    reg        active;
    reg [14:0] a;

    assign busy = active;

    always @(posedge clk) begin
        we   <= 0;
        done <= 0;
        if (!resetn) begin
            active <= 0;
        end else if (!active) begin
            if (start) begin a <= 0; active <= 1; end
        end else begin
            we <= 1; waddr <= a; wdata <= 3'b000;
            if (a == 15'd19199) begin active <= 0; done <= 1; end
            else a <= a + 15'd1;
        end
    end
endmodule
