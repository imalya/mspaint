// tool_select_fsm.v
// Tracks the selected tool + color and turns mouse button events into
// engine commands.
//
// Toolbar item encoding (tb_idx, from your toolbar hit-test):
//   0 = PEN, 1 = ERASER, 2 = LINE        (tb_idx[3] == 0)
//   8..15  = color 0..7 (color = tb_idx[2:0], {R,G,B})   (tb_idx[3] == 1)
//
// Behaviour:
//   - press on toolbar        -> update tool/color, wait for release
//   - press on canvas         -> latch start point, enter DRAG
//   - release (DRAG -> COMMIT)-> one-cycle line_start if tool == LINE
module tool_select_fsm (
    input            clk,
    input            resetn,
    input            btn_left,     // level, left mouse button
    input            tb_hit,       // cursor is over a toolbar item
    input      [3:0] tb_idx,       // which item (valid when tb_hit)
    input      [7:0] cx,           // cursor x, canvas coords 0..159
    input      [6:0] cy,           // cursor y, canvas coords 0..119
    output reg [1:0] tool,
    output reg [2:0] color,
    output reg [7:0] start_x,      // where the drag began
    output reg [6:0] start_y,
    output           pen_en,       // level: dragging with pen
    output           erase_en,     // level: dragging with eraser
    output           line_start    // 1-cycle pulse on release with line tool
);
    localparam [1:0] T_PEN = 2'd0, T_ERASER = 2'd1, T_LINE = 2'd2;
    localparam [2:0] S_IDLE = 3'd0, S_TB = 3'd1, S_WAIT_REL = 3'd2,
                     S_DRAG = 3'd3, S_COMMIT = 3'd4;

    reg [2:0] state;
    reg       btn_d;
    reg [3:0] idx_l;
    wire      press = btn_left & ~btn_d;

    always @(posedge clk) begin
        if (!resetn) begin
            state   <= S_IDLE;
            btn_d   <= 1'b0;
            tool    <= T_PEN;
            color   <= 3'b111;     // white
            start_x <= 8'd0;
            start_y <= 7'd0;
            idx_l   <= 4'd0;
        end else begin
            btn_d <= btn_left;
            case (state)
                S_IDLE: if (press) begin
                    if (tb_hit) begin
                        idx_l <= tb_idx;
                        state <= S_TB;
                    end else begin
                        start_x <= cx;
                        start_y <= cy;
                        state   <= S_DRAG;
                    end
                end
                S_TB: begin
                    if (idx_l[3])                  color <= idx_l[2:0];
                    else if (idx_l[2:0] <= T_LINE) tool  <= idx_l[1:0];
                    state <= S_WAIT_REL;
                end
                S_WAIT_REL: if (!btn_left) state <= S_IDLE;
                S_DRAG:     if (!btn_left) state <= S_COMMIT;
                S_COMMIT:   state <= S_IDLE;
                default:    state <= S_IDLE;
            endcase
        end
    end

    assign pen_en     = (state == S_DRAG)   && (tool == T_PEN);
    assign erase_en   = (state == S_DRAG)   && (tool == T_ERASER);
    assign line_start = (state == S_COMMIT) && (tool == T_LINE);
endmodule
