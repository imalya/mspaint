// AI-ASSISTED (Claude): cursor position tracker with edge clamping.
// Each packet moves the cursor by (dx, dy). Mouse Y grows upward, screen Y grows
// downward, so dy is subtracted. The cursor stops at the canvas edges (no wrapping).
`timescale 1ns/1ps
module mouse_tracker (
    input             clk,
    input             resetn,
    input             pkt_valid,
    input      [2:0]  btn,
    input signed [8:0] dx,
    input signed [8:0] dy,
    output reg [7:0]  cursor_x,      // 0..159
    output reg [7:0]  cursor_y,      // 0..119
    output reg        button         // left button held
);
    localparam W = 160, H = 120;
    reg signed [10:0] nx, ny;

    always @(posedge clk) begin
        if (!resetn) begin
            cursor_x <= 80;
            cursor_y <= 60;
            button   <= 0;
        end else if (pkt_valid) begin
            button <= btn[0];
            nx = $signed({2'b00, cursor_x}) + dx;
            ny = $signed({2'b00, cursor_y}) - dy;
            if (nx < 0)        cursor_x <= 0;
            else if (nx > W-1) cursor_x <= W-1;
            else               cursor_x <= nx[7:0];
            if (ny < 0)        cursor_y <= 0;
            else if (ny > H-1) cursor_y <= H-1;
            else               cursor_y <= ny[7:0];
        end
    end
endmodule
