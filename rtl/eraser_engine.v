// AI-ASSISTED (Claude): eraser engine.
// While active, clears a 3x3 square around the cursor to black (colour 0).
// It cycles through the 9 offsets, one pixel per clock, so the whole square is
// rewritten every 9 clocks. Pixels outside the drawing area are skipped.
`timescale 1ns/1ps
module eraser_engine #(parameter YMAX = 111) (   // last drawable row
    input             clk,
    input             resetn,
    input             active,           // button held with the eraser tool
    input      [7:0]  cursor_x,
    input      [7:0]  cursor_y,
    output reg        we,
    output reg [14:0] waddr,
    output reg [2:0]  wdata
);
    reg [1:0] ox, oy;                  // 0,1,2 -> offset -1,0,+1
    reg signed [9:0] px, py;           // pixel being erased (can be -1)

    always @(posedge clk) begin
        if (!resetn) begin
            we <= 0; waddr <= 0; wdata <= 0; ox <= 0; oy <= 0;
        end else begin
            we    <= 0;
            wdata <= 3'b000;
            if (active) begin
                px = $signed({2'b00, cursor_x}) + $signed({1'b0, ox}) - 10'sd1;
                py = $signed({2'b00, cursor_y}) + $signed({1'b0, oy}) - 10'sd1;
                if (px >= 0 && px <= 159 && py >= 0 && py <= YMAX) begin
                    we    <= 1;
                    waddr <= py[6:0] * 160 + px[7:0];
                end
                // next offset: ox 0..2, then oy 0..2
                if (ox == 2) begin
                    ox <= 0;
                    oy <= (oy == 2) ? 2'd0 : oy + 2'd1;
                end else
                    ox <= ox + 2'd1;
            end else begin
                ox <= 0; oy <= 0;
            end
        end
    end
endmodule
