// line_engine.v  -- all-octant Bresenham, one pixel per 2 clocks.
// Pulse start for 1 cycle (when !busy) with endpoints + color; inputs are
// latched. plot is high for one cycle per pixel; write x/y/color to canvas
// RAM while plot = 1. done pulses for 1 cycle at the end.
module line_engine (
    input            clk,
    input            resetn,
    input            start,
    input      [7:0] x0_in, x1_in,
    input      [6:0] y0_in, y1_in,
    input      [2:0] color_in,
    output     [7:0] x_out,
    output     [6:0] y_out,
    output     [2:0] color_out,
    output           plot,
    output           busy,
    output           done
);
    localparam [1:0] IDLE = 2'd0, PLOT = 2'd1, STEP = 2'd2, FINISH = 2'd3;

    reg [1:0]        state;
    reg signed [9:0] x, y, x1, y1, dx, dy, err;
    reg              sx_pos, sy_pos;   // step direction: 1 = +1, 0 = -1
    reg [2:0]        col;

    // Setup values from the (unlatched) inputs
    wire        xdir  = (x1_in >= x0_in);
    wire        ydir  = (y1_in >= y0_in);
    wire [7:0]  adx   = xdir ? (x1_in - x0_in) : (x0_in - x1_in);
    wire [6:0]  ady   = ydir ? (y1_in - y0_in) : (y0_in - y1_in);
    wire signed [9:0] dx_w = {2'b00, adx};
    wire signed [9:0] dy_w = -{3'b000, ady};

    // Bresenham decision
    wire signed [10:0] e2 = err <<< 1;

    reg signed [9:0] err_n, x_n, y_n;

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            x <= 0; y <= 0; x1 <= 0; y1 <= 0; dx <= 0; dy <= 0; err <= 0;
            sx_pos <= 1'b1; sy_pos <= 1'b1; col <= 3'b0;
        end else begin
            case (state)
                IDLE: if (start) begin
                    x   <= {2'b00, x0_in};
                    y   <= {3'b000, y0_in};
                    x1  <= {2'b00, x1_in};
                    y1  <= {3'b000, y1_in};
                    dx  <= dx_w;
                    dy  <= dy_w;
                    err <= dx_w + dy_w;
                    sx_pos <= xdir;
                    sy_pos <= ydir;
                    col <= color_in;
                    state <= PLOT;
                end
                PLOT: state <= STEP;       // plot is high this cycle
                STEP: begin
                    if (x == x1 && y == y1) begin
                        state <= FINISH;
                    end else begin
                        err_n = err; x_n = x; y_n = y;
                        if (e2 >= dy) begin
                            err_n = err_n + dy;
                            x_n   = sx_pos ? x + 10'sd1 : x - 10'sd1;
                        end
                        if (e2 <= dx) begin
                            err_n = err_n + dx;
                            y_n   = sy_pos ? y + 10'sd1 : y - 10'sd1;
                        end
                        err <= err_n; x <= x_n; y <= y_n;
                        state <= PLOT;
                    end
                end
                FINISH: state <= IDLE;
            endcase
        end
    end

    assign x_out     = x[7:0];
    assign y_out     = y[6:0];
    assign color_out = col;
    assign plot      = (state == PLOT);
    assign busy      = (state != IDLE);
    assign done      = (state == FINISH);
endmodule
