
`timescale 1ns/1ps
module line_engine (
    input             clk,
    input             resetn,
    input             start,
    input      [7:0]  x0, y0, x1, y1,
    input      [2:0]  colour,
    output reg        we,
    output reg [14:0] waddr,
    output reg [2:0]  wdata,
    output            busy,
    output reg        done
);
    localparam IDLE = 1'b0, DRAW = 1'b1;
    reg state;

    reg signed [9:0]  x, y, xe, ye;    // current point and end point
    reg signed [9:0]  dx, dy;          // dx >= 0, dy <= 0
    reg signed [9:0]  sx, sy;          // step direction: +1 or -1
    reg signed [11:0] err;
    reg        [2:0]  col;

    wire [7:0] adx = (x1 >= x0) ? x1 - x0 : x0 - x1;
    wire [7:0] ady = (y1 >= y0) ? y1 - y0 : y0 - y1;
    wire signed [11:0] e2 = err <<< 1;
    wire step_x = (e2 >= dy);
    wire step_y = (e2 <= dx);

    assign busy = (state == DRAW);

    always @(posedge clk) begin
        we   <= 0;
        done <= 0;
        if (!resetn) begin
            state <= IDLE;
        end else case (state)
            IDLE: if (start) begin
                x   <= {2'b00, x0};  y  <= {2'b00, y0};
                xe  <= {2'b00, x1};  ye <= {2'b00, y1};
                dx  <= {2'b00, adx};
                dy  <= -$signed({2'b00, ady});
                sx  <= (x1 >= x0) ? 10'sd1 : -10'sd1;
                sy  <= (y1 >= y0) ? 10'sd1 : -10'sd1;
                err <= $signed({4'b0000, adx}) - $signed({4'b0000, ady});
                col <= colour;
                state <= DRAW;
            end
            DRAW: begin
                we    <= 1;
                waddr <= y[6:0] * 160 + x[7:0];
                wdata <= col;
                if (x == xe && y == ye) begin
                    state <= IDLE;
                    done  <= 1;
                end else begin
                    if (step_x) x <= x + sx;
                    if (step_y) y <= y + sy;
                    err <= err + (step_x ? dy : 10'sd0) + (step_y ? dx : 10'sd0);
                end
            end
        endcase
    end
endmodule
