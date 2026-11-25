
`timescale 1ns/1ps
module rect_engine (
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
    localparam IDLE = 3'd0, TOP_E = 3'd1, BOT_E = 3'd2, LEFT_E = 3'd3, RIGHT_E = 3'd4;
    reg [2:0] state;
    reg [7:0] xl, xr, yt, yb;          // left, right, top, bottom
    reg [7:0] i;                       // position along the current edge
    reg [2:0] col;

    assign busy = (state != IDLE);

    always @(posedge clk) begin
        we   <= 0;
        done <= 0;
        if (!resetn) begin
            state <= IDLE;
        end else case (state)
            IDLE: if (start) begin
                xl  <= (x0 < x1) ? x0 : x1;
                xr  <= (x0 < x1) ? x1 : x0;
                yt  <= (y0 < y1) ? y0 : y1;
                yb  <= (y0 < y1) ? y1 : y0;
                i   <= (x0 < x1) ? x0 : x1;
                col <= colour;
                state <= TOP_E;
            end
            TOP_E: begin                       // (i, yt) for i = xl..xr
                we <= 1; wdata <= col; waddr <= yt * 160 + i;
                if (i == xr) begin i <= xl; state <= BOT_E; end
                else i <= i + 1;
            end
            BOT_E: begin                       // (i, yb) for i = xl..xr
                we <= 1; wdata <= col; waddr <= yb * 160 + i;
                if (i == xr) begin i <= yt; state <= LEFT_E; end
                else i <= i + 1;
            end
            LEFT_E: begin                      // (xl, i) for i = yt..yb
                we <= 1; wdata <= col; waddr <= i * 160 + xl;
                if (i == yb) begin i <= yt; state <= RIGHT_E; end
                else i <= i + 1;
            end
            RIGHT_E: begin                     // (xr, i) for i = yt..yb
                we <= 1; wdata <= col; waddr <= i * 160 + xr;
                if (i == yb) begin state <= IDLE; done <= 1; end
                else i <= i + 1;
            end
            default: state <= IDLE;
        endcase
    end
endmodule
