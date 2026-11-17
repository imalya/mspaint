
`timescale 1ns/1ps
module canvas_ram (
    input            clk,
    input            we, //write enable
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
