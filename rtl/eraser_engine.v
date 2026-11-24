// eraser_engine.v -- stamps a SIZE x SIZE black square around (cx, cy).
// Pulse start for 1 cycle (when !busy); center is latched and clamped so the
// square stays inside the 160x120 canvas. 1 pixel per clock.
module eraser_engine #(parameter SIZE = 4) (
    input            clk,
    input            resetn,
    input            start,
    input      [7:0] cx,
    input      [6:0] cy,
    output     [7:0] x_out,
    output     [6:0] y_out,
    output     [2:0] color_out,
    output           plot,
    output           busy
);
    localparam HALF = SIZE / 2;
    localparam [7:0] X_MAX = 160 - SIZE;
    localparam [6:0] Y_MAX = 120 - SIZE;

    // top-left corner of the stamp, clamped to the canvas
    wire [7:0] ox = (cx < HALF) ? 8'd0 :
                    ((cx - HALF) > X_MAX) ? X_MAX : (cx - HALF);
    wire [6:0] oy = (cy < HALF) ? 7'd0 :
                    ((cy - HALF) > Y_MAX) ? Y_MAX : (cy - HALF);

    reg        active;
    reg [7:0]  ox_r;
    reg [6:0]  oy_r;
    reg [3:0]  i, j;

    always @(posedge clk) begin
        if (!resetn) begin
            active <= 1'b0; ox_r <= 0; oy_r <= 0; i <= 0; j <= 0;
        end else if (!active) begin
            if (start) begin
                ox_r <= ox; oy_r <= oy; i <= 0; j <= 0; active <= 1'b1;
            end
        end else begin
            if (i == SIZE - 1) begin
                i <= 0;
                if (j == SIZE - 1) active <= 1'b0;
                else               j <= j + 4'd1;
            end else begin
                i <= i + 4'd1;
            end
        end
    end

    assign x_out     = ox_r + i;
    assign y_out     = oy_r + j;
    assign color_out = 3'b000;      // black = background
    assign plot      = active;
    assign busy      = active;
endmodule
