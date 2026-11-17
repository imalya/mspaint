
`timescale 1ns/1ps
module canvas_ram (
    input            clk,
    input            we, //write enable
    input      [14:0] waddr,//adress (which pixel to write)
    input      [2:0]  wdata,//color (3 bits so 8 colors)
    input      [14:0] raddr,//which pixel to look up
    output reg [2:0]  q//what color was read
);
    reg [2:0] mem [0:19199];          // 160 * 120
    always @(posedge clk) begin
        if (we) mem[waddr] <= wdata; //If write enable is 1, store wdata into the slot at waddr
        q <= mem[raddr];//copy the value at raddr into q
    end
endmodule
