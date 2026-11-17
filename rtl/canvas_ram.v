// AI-ASSISTED (Claude): canvas framebuffer, 160x120, 3-bit colour.
// One write port (pen engine), one read port (display FSM), 1-cycle read latency.
`timescale 1ns/1ps
module canvas_ram (
    input            clk,
    input            we,
    input      [14:0] waddr,
    input      [2:0]  wdata,
    input      [14:0] raddr,
    output reg [2:0]  q
);
    reg [2:0] mem [0:19199];          // 160 * 120
    always @(posedge clk) begin
        if (we) mem[waddr] <= wdata;
        q <= mem[raddr];
    end
endmodule
